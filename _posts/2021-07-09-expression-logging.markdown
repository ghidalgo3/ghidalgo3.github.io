---
layout: post
title:  "Logging with Expressions"
date:   2021-07-09 12:34:23 -0400
categories: c#
---
# Problem
We recently had a problem at work where a piece of code was throwing an exception with the message "System variable should be X but is Y". The problem was that we had no idea _which_ value was incorrectly set, and we were so deep into highly reusable generic code that pushing the value name via method parameter would have required touching dozens of call sites.

To concretize this, we have something like this (types have been altered for their safety :)):

```csharp
// This class is auto-generated from an RPC specification.
// It contains many get/set method pairs that wrap the underlying values the remote system exposes.
// We wrote the code generation system such that the name of value being accesses is part of the method name, which also makes it easy to spot when someone makes a breaking change to the RPC contact because code stops compiling!
public class RemoteSystemClient
{
    Task SetValue1(int newValue) { ... }
    Task<int> GetValue1() { ... }
    Task SetValue2(string newValue) { ... }
    Task<string> GetValue2() { ... }
    ...
}

// This remote system takes some time to change state when you call a setter, what we really wanted was to block until we could observe that the state really changed.
public static class RemoteSystemClientExtension
{
    public static async Task PollUntilExpectedAsync<T>(Func<Task<T>> getter, T expectedValue)
    where T : IEquatable<T>
    {
        for (
            int i = 0;
            (await getter.Invoke()).Equals(expectedValue) && i < 3;)
        {
            await Task.Delay(TimeSpan.FromSeconds(1));
            i++;
        }
        if (!(await getter.Invoke()).Equals(expectedValue))
        {

                // Here is the problem! I have no idea which value has an incorrect value.
                throw new ValueDidNotSetException($"Expected: {expectedValue}, Actual {await getter.Invoke()}");
        }
    }
}
```

When a `ValueDidNotSetException` is thrown, we could only hope that the stack trace contained enough information to know which code path we were on to deduce which configuration value was not being set in time.

The quickest solution to this would be to add an argument to `PollUntilExpectedAsync` that identifies the value being set. 

Instead of:
```csharp
client.PollUntilExpectedAsync(async () => await client.GetValue1, expectedValue: 1);
```
We would write
```csharp
client.PollUntilExpectedAsync(async () => await client.GetValue1(), expectedValue: 1, name: "Value1");
```
The problem with this approach is that we would have to change all call sites of `PollUntilExpectedAsync` and pass the correct configuration value name.
We could have used a default parameter value to avoid having to modify so much code, but that would not actually address the problem: we still do not know what method we're calling and so we do not know which configuration value is not being set.
We looked at this and thought "You know, if only we could get the name of the method being called we could put that in the exception message and not have to change all the callers".
That's exactly what C# Expression trees were made for!
I spend the next day reading through the documentation and here's what I came up with.

# Solution
Here is our starting point: 
```csharp
var client = new RemoteSystemClient();
await RemoteSystemClientExtension.PollUntilExpectedAsync(client.GetValue1, 2);
```
When run, this throws an exception like this:
```
Unhandled exception. expressions.ValueDidNotSetException: Expected: 2, Actual 1
   at expressions.RemoteSystemClientExtension.PollUntilExpectedAsync[T](Func`1 getter, T expectedValue) in /Users/gustavo/code/expressions/Program.cs:line 32
   at expressions.Program.Main(String[] args) in /Users/gustavo/code/expressions/Program.cs:line 47
   at expressions.Program.<Main>(String[] args)
```

No mention whatsoever about Value1! Let's see how we can improve `PollUntilExpectedAsync`:

1. Copy the original method and change the first argument from `Func<Task<T>>>` to `Expression<Func<Task<T>>>`. I simply wrapped the original argument type (which must be a [delegate] type ) in an `Expression`. This will be our new public method.
1. I make the original method private and add one more argument called `accessorName`. This will be the name of the method that I want to include in the exception message.
1. Then I write the C# expression code.
```
private static async Task PollUntilExpectedAsyncImpl<T>(
    Func<Task<T>> getter,
    T expectedValue,
    string accessorName)
{
    ...
            throw new ValueDidNotSetException($"Expected: {expectedValue}, Actual {await getter.Invoke()}. Accessor: {accessorName}");
}

public static async Task PollUntilExpectedAsync<T>(Expression<Func<Task<T>>> getter, T expectedValue)
{
    var method = getter.Body as MethodCallExpression;
    var innerGetter = getter.Compile();
    await PollUntilExpectedAsyncImpl(innerGetter, expectedValue, method.Method.Name);
}
```

I don't have to change my original test code, and now I get this exception:

```
Unhandled exception. expressions.ValueDidNotSetException: Expected: 2, Actual 1. ***Accessor: GetValue1***
   at expressions.RemoteSystemClientExtension.PollUntilExpectedAsyncImpl[T](Func`1 getter, T expectedValue, String accessorName) in /Users/gustavo/code/expressions/Program.cs:line 34
   at expressions.RemoteSystemClientExtension.PollUntilExpectedAsync[T](Expression`1 getter, T expectedValue) in /Users/gustavo/code/expressions/Program.cs:line 43
   at expressions.Program.Main(String[] args) in /Users/gustavo/code/expressions/Program.cs:line 53
   at expressions.Program.<Main>(String[] args)
```

Notice how the name of the accessor method is included in the exception message, making it really easy to track down which configuration is not being set in time.

# Is this any good?
You might spot that this `Expression` stuff is a lot like using reflection.
## Performance
## Readability

# Conclusion

[delegate]: https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/delegates/