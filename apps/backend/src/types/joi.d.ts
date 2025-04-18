declare module 'joi' {
  export = Joi;
  namespace Joi {
    interface StringSchema extends AnySchema {
      valid(...values: any[]): this;
    }
    interface NumberSchema extends AnySchema {
      default(value: number): this;
    }
    interface AnySchema {
      required(): this;
      default(value: any): this;
    }
    export function object(schema: object): ObjectSchema;
    export function string(): StringSchema;
    export function number(): NumberSchema;
    interface ObjectSchema extends AnySchema {
      // Add any additional methods needed
    }
  }
}
