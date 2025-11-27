# 1.0.0

* Renaming members for better intuitivity
* Adding scoped `Scope`, so features can be scoped and disposed when the `Scope` is disposed

### 1.0.1

* Improving logging: support for external logging and simpler log messages

### 1.0.2

* Fixed logging on component changes

### 1.0.3

* Fixed wrong class name (FlowFeatureDisposalLogic)

### 1.0.4

* Fixed bug in FlowScope getComponent
* Added getComponentOrNull

## 1.1.0

* Added support for `dispose` in all types of Logic (it will be called once a `FlowFeature` is disposed)
  This allows, for example, to get a `StreamSubscription<T>` and then close it when it is no longer needed.

### 1.1.1

* Fixed the order of logic disposal and potentially duplicate `dispose` calls

## 1.2.0

* Added support for listening on state changes inside `FlowLogic`
* All components have now a `dispose` method

## 1.3.0

* Added `FlowEventLogic<T>` for immutable, data-carrying events
  - Events can now carry typed data instead of relying on mutable state
  - New `flow.dispatch(event)` method for triggering immutable events
  - Type-safe event handling with `react(T event)` method
  - Optional event filtering with `reactsIf(T event)`
  - Fully backward compatible with existing `FlowEvent` pattern

### 1.3.1

* Fixed incorrect `@protected` annotation on `FlowManager.dispatch` - dispatch should be public
* Removed unnecessary use of dynamic types in event handling
* Improved type safety throughout the event system
