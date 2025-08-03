import 'package:test/test.dart';

import 'package:ai_webscraper/src/utils/schema_validator.dart';
import 'package:ai_webscraper/src/core/exceptions.dart';

void main() {
  group('SchemaValidator', () {
    late SchemaValidator validator;

    setUp(() {
      validator = SchemaValidator();
    });

    group('Basic Validation Tests', () {
      test('should accept valid simple schema', () {
        const validSchema = {
          'title': 'string',
          'price': 'number',
          'available': 'boolean',
        };

        expect(() => validator.validate(validSchema), returnsNormally);
      });

      test('should throw exception for empty schema', () {
        const emptySchema = <String, String>{};

        expect(
          () => validator.validate(emptySchema),
          throwsA(isA<SchemaValidationException>().having(
            (e) => e.message,
            'message',
            equals('Schema cannot be empty'),
          )),
        );
      });

      test('should throw exception for empty field name', () {
        const invalidSchema = {
          '': 'string',
          'price': 'number',
        };

        expect(
          () => validator.validate(invalidSchema),
          throwsA(isA<SchemaValidationException>().having(
            (e) => e.message,
            'message',
            equals('Schema field names cannot be empty'),
          )),
        );
      });

      test('should throw exception for whitespace-only field name', () {
        const invalidSchema = {
          '   ': 'string',
          'price': 'number',
        };

        expect(
          () => validator.validate(invalidSchema),
          throwsA(isA<SchemaValidationException>().having(
            (e) => e.message,
            'message',
            equals('Schema field names cannot be empty'),
          )),
        );
      });

      test('should throw exception for empty field type', () {
        const invalidSchema = {
          'title': '',
          'price': 'number',
        };

        expect(
          () => validator.validate(invalidSchema),
          throwsA(isA<SchemaValidationException>().having(
            (e) => e.message,
            'message',
            contains('Schema field type cannot be empty for field "title"'),
          )),
        );
      });

      test('should throw exception for whitespace-only field type', () {
        const invalidSchema = {
          'title': '   ',
          'price': 'number',
        };

        expect(
          () => validator.validate(invalidSchema),
          throwsA(isA<SchemaValidationException>().having(
            (e) => e.message,
            'message',
            contains('Schema field type cannot be empty for field "title"'),
          )),
        );
      });
    });

    group('Supported Types Tests', () {
      test('should accept all supported types', () {
        const supportedTypes = {
          'string_field': 'string',
          'number_field': 'number',
          'integer_field': 'integer',
          'boolean_field': 'boolean',
          'array_field': 'array',
          'object_field': 'object',
          'date_field': 'date',
          'url_field': 'url',
          'email_field': 'email',
          'text_field': 'text',
        };

        expect(() => validator.validate(supportedTypes), returnsNormally);
      });

      test('should accept case-insensitive types', () {
        const caseInsensitiveSchema = {
          'title': 'STRING',
          'price': 'Number',
          'available': 'BOOLEAN',
          'tags': 'Array',
        };

        expect(
            () => validator.validate(caseInsensitiveSchema), returnsNormally);
      });

      test('should accept types with extra whitespace', () {
        const whitespaceSchema = {
          'title': ' string ',
          'price': '  number  ',
          'available': '\tboolean\t',
        };

        expect(() => validator.validate(whitespaceSchema), returnsNormally);
      });

      test('should throw exception for unsupported type', () {
        const invalidSchema = {
          'title': 'string',
          'custom_field': 'unsupported_type',
        };

        expect(
          () => validator.validate(invalidSchema),
          throwsA(isA<SchemaValidationException>().having(
            (e) => e.message,
            'message',
            contains(
                'Unsupported schema type "unsupported_type" for field "custom_field"'),
          )),
        );
      });

      test('should list supported types in error message', () {
        const invalidSchema = {'field': 'invalid_type'};

        try {
          validator.validate(invalidSchema);
          fail('Should have thrown SchemaValidationException');
        } catch (e) {
          expect(e.toString(), contains('string'));
          expect(e.toString(), contains('number'));
          expect(e.toString(), contains('boolean'));
          expect(e.toString(), contains('array'));
          expect(e.toString(), contains('object'));
        }
      });
    });

    group('Type Support Checking Tests', () {
      test('should correctly identify supported types', () {
        expect(validator.isTypeSupported('string'), isTrue);
        expect(validator.isTypeSupported('number'), isTrue);
        expect(validator.isTypeSupported('integer'), isTrue);
        expect(validator.isTypeSupported('boolean'), isTrue);
        expect(validator.isTypeSupported('array'), isTrue);
        expect(validator.isTypeSupported('object'), isTrue);
        expect(validator.isTypeSupported('date'), isTrue);
        expect(validator.isTypeSupported('url'), isTrue);
        expect(validator.isTypeSupported('email'), isTrue);
        expect(validator.isTypeSupported('text'), isTrue);
      });

      test('should correctly identify unsupported types', () {
        expect(validator.isTypeSupported('unsupported'), isFalse);
        expect(validator.isTypeSupported('float'), isFalse);
        expect(validator.isTypeSupported('double'), isFalse);
        expect(validator.isTypeSupported('list'), isFalse);
        expect(validator.isTypeSupported('map'), isFalse);
      });

      test('should handle case-insensitive type checking', () {
        expect(validator.isTypeSupported('STRING'), isTrue);
        expect(validator.isTypeSupported('Number'), isTrue);
        expect(validator.isTypeSupported('BOOLEAN'), isTrue);
        expect(validator.isTypeSupported('Array'), isTrue);
      });

      test('should handle whitespace in type checking', () {
        expect(validator.isTypeSupported(' string '), isTrue);
        expect(validator.isTypeSupported('  number  '), isTrue);
        expect(validator.isTypeSupported('\tboolean\t'), isTrue);
      });
    });

    group('Supported Types Property Tests', () {
      test('should return immutable set of supported types', () {
        final supportedTypes = validator.supportedTypes;

        expect(supportedTypes, isA<Set<String>>());
        expect(supportedTypes, contains('string'));
        expect(supportedTypes, contains('number'));
        expect(supportedTypes, contains('integer'));
        expect(supportedTypes, contains('boolean'));
        expect(supportedTypes, contains('array'));
        expect(supportedTypes, contains('object'));
        expect(supportedTypes, contains('date'));
        expect(supportedTypes, contains('url'));
        expect(supportedTypes, contains('email'));
        expect(supportedTypes, contains('text'));
      });

      test('should return modifiable copy of supported types', () {
        final supportedTypes = validator.supportedTypes;
        final originalSize = supportedTypes.length;

        // Try to modify the returned set
        supportedTypes.add('custom_type');

        // Original validator should not be affected
        expect(validator.supportedTypes.length, equals(originalSize));
        expect(validator.isTypeSupported('custom_type'), isFalse);
      });

      test('should contain exactly the expected types', () {
        const expectedTypes = {
          'string',
          'number',
          'integer',
          'boolean',
          'array',
          'object',
          'date',
          'url',
          'email',
          'text',
        };

        expect(validator.supportedTypes, equals(expectedTypes));
      });
    });

    group('Schema Normalization Tests', () {
      test('should normalize field types to lowercase', () {
        const unnormalizedSchema = {
          'title': 'STRING',
          'price': 'Number',
          'available': 'BOOLEAN',
          'tags': 'Array',
        };

        final normalized = validator.normalize(unnormalizedSchema);

        expect(normalized['title'], equals('string'));
        expect(normalized['price'], equals('number'));
        expect(normalized['available'], equals('boolean'));
        expect(normalized['tags'], equals('array'));
      });

      test('should trim whitespace from field names and types', () {
        const whitespaceSchema = {
          ' title ': ' string ',
          '  price  ': '  number  ',
          '\tavailable\t': '\tboolean\t',
        };

        final normalized = validator.normalize(whitespaceSchema);

        expect(normalized.keys, containsAll(['title', 'price', 'available']));
        expect(normalized['title'], equals('string'));
        expect(normalized['price'], equals('number'));
        expect(normalized['available'], equals('boolean'));
      });

      test('should preserve original schema structure', () {
        const originalSchema = {
          'title': 'STRING',
          'price': 'Number',
          'available': 'BOOLEAN',
        };

        final normalized = validator.normalize(originalSchema);

        expect(normalized.length, equals(originalSchema.length));
        expect(normalized.keys.length, equals(originalSchema.keys.length));
      });

      test('should handle empty normalization gracefully', () {
        const emptySchema = <String, String>{};

        final normalized = validator.normalize(emptySchema);

        expect(normalized, isEmpty);
      });
    });

    group('Validate and Normalize Tests', () {
      test('should validate and normalize valid schema', () {
        const inputSchema = {
          'Title': 'STRING',
          ' Price ': ' Number ',
          'available': 'BOOLEAN',
        };

        final result = validator.validateAndNormalize(inputSchema);

        expect(result['Title'], equals('string'));
        expect(result['Price'], equals('number'));
        expect(result['available'], equals('boolean'));
      });

      test(
          'should throw exception during validate and normalize for invalid schema',
          () {
        const invalidSchema = {
          'title': 'string',
          'invalid_field': 'unsupported_type',
        };

        expect(
          () => validator.validateAndNormalize(invalidSchema),
          throwsA(isA<SchemaValidationException>()),
        );
      });

      test('should handle empty schema in validate and normalize', () {
        const emptySchema = <String, String>{};

        expect(
          () => validator.validateAndNormalize(emptySchema),
          throwsA(isA<SchemaValidationException>()),
        );
      });

      test('should process complex valid schema', () {
        const complexSchema = {
          'Product_Name': 'STRING',
          ' product_price ': ' NUMBER ',
          'InStock': 'Boolean',
          'tags': 'ARRAY',
          'metadata': 'object',
          'created_date': 'date',
          'website_url': 'url',
          'contact_email': 'email',
          'description': 'text',
          'quantity': 'integer',
        };

        final result = validator.validateAndNormalize(complexSchema);

        expect(result['Product_Name'], equals('string'));
        expect(result['product_price'], equals('number'));
        expect(result['InStock'], equals('boolean'));
        expect(result['tags'], equals('array'));
        expect(result['metadata'], equals('object'));
        expect(result['created_date'], equals('date'));
        expect(result['website_url'], equals('url'));
        expect(result['contact_email'], equals('email'));
        expect(result['description'], equals('text'));
        expect(result['quantity'], equals('integer'));
      });
    });

    group('Edge Cases and Error Handling Tests', () {
      test('should handle schema with special characters in field names', () {
        const specialCharSchema = {
          'field-with-dashes': 'string',
          'field_with_underscores': 'number',
          'field.with.dots': 'boolean',
          'field@with@symbols': 'text',
        };

        expect(() => validator.validate(specialCharSchema), returnsNormally);
      });

      test('should handle very long field names', () {
        final longFieldName = 'a' * 100;
        final longFieldSchema = {
          longFieldName: 'string',
          'normal_field': 'number',
        };

        expect(() => validator.validate(longFieldSchema), returnsNormally);
      });

      test('should handle many fields in schema', () {
        final manyFieldsSchema = <String, String>{};
        for (int i = 0; i < 100; i++) {
          manyFieldsSchema['field_$i'] = 'string';
        }

        expect(() => validator.validate(manyFieldsSchema), returnsNormally);
      });

      test('should handle unicode characters in field names', () {
        const unicodeSchema = {
          'título': 'string',
          'preço': 'number',
          'disponível': 'boolean',
          '名前': 'text',
          '価格': 'number',
        };

        expect(() => validator.validate(unicodeSchema), returnsNormally);
      });

      test('should maintain consistent behavior across multiple validations',
          () {
        const testSchema = {
          'title': 'string',
          'price': 'number',
          'available': 'boolean',
        };

        // Run validation multiple times
        for (int i = 0; i < 10; i++) {
          expect(() => validator.validate(testSchema), returnsNormally);
        }
      });
    });

    group('Type-Specific Validation Tests', () {
      test('should accept all string-like types', () {
        const stringTypes = {
          'title': 'string',
          'description': 'text',
          'email': 'email',
          'website': 'url',
        };

        expect(() => validator.validate(stringTypes), returnsNormally);
      });

      test('should accept all numeric types', () {
        const numericTypes = {
          'price': 'number',
          'quantity': 'integer',
        };

        expect(() => validator.validate(numericTypes), returnsNormally);
      });

      test('should accept complex data types', () {
        const complexTypes = {
          'is_available': 'boolean',
          'tags': 'array',
          'metadata': 'object',
          'created_at': 'date',
        };

        expect(() => validator.validate(complexTypes), returnsNormally);
      });

      test('should handle mixed type schemas', () {
        const mixedSchema = {
          'name': 'string',
          'age': 'integer',
          'height': 'number',
          'is_active': 'boolean',
          'hobbies': 'array',
          'address': 'object',
          'birth_date': 'date',
          'email': 'email',
          'website': 'url',
          'bio': 'text',
        };

        expect(() => validator.validate(mixedSchema), returnsNormally);
      });
    });

    group('Performance Tests', () {
      test('should handle large schemas efficiently', () {
        final largeSchema = <String, String>{};
        const supportedTypes = [
          'string',
          'number',
          'integer',
          'boolean',
          'array',
          'object',
          'date',
          'url',
          'email',
          'text'
        ];

        for (int i = 0; i < 1000; i++) {
          largeSchema['field_$i'] = supportedTypes[i % supportedTypes.length];
        }

        final stopwatch = Stopwatch()..start();
        validator.validate(largeSchema);
        stopwatch.stop();

        // Validation should be fast even for large schemas
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should handle repeated validations efficiently', () {
        const testSchema = {
          'title': 'string',
          'price': 'number',
          'available': 'boolean',
          'tags': 'array',
          'metadata': 'object',
        };

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          validator.validate(testSchema);
        }
        stopwatch.stop();

        // Repeated validations should be fast
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Integration Tests', () {
      test('should work with real-world e-commerce schema', () {
        const ecommerceSchema = {
          'product_name': 'string',
          'product_price': 'number',
          'sale_price': 'number',
          'currency': 'string',
          'in_stock': 'boolean',
          'stock_quantity': 'integer',
          'product_description': 'text',
          'product_images': 'array',
          'specifications': 'object',
          'category': 'string',
          'brand': 'string',
          'rating': 'number',
          'review_count': 'integer',
          'product_url': 'url',
          'created_date': 'date',
          'updated_date': 'date',
        };

        expect(() => validator.validate(ecommerceSchema), returnsNormally);

        final normalized = validator.validateAndNormalize(ecommerceSchema);
        expect(normalized.length, equals(ecommerceSchema.length));
      });

      test('should work with real-world news article schema', () {
        const newsSchema = {
          'headline': 'string',
          'subheadline': 'string',
          'article_body': 'text',
          'author': 'string',
          'publication_date': 'date',
          'category': 'string',
          'tags': 'array',
          'word_count': 'integer',
          'reading_time': 'number',
          'is_premium': 'boolean',
          'article_url': 'url',
          'author_email': 'email',
          'social_shares': 'object',
          'related_articles': 'array',
        };

        expect(() => validator.validate(newsSchema), returnsNormally);

        final normalized = validator.validateAndNormalize(newsSchema);
        expect(normalized.length, equals(newsSchema.length));
      });

      test('should work with real-world contact form schema', () {
        const contactSchema = {
          'full_name': 'string',
          'email_address': 'email',
          'phone_number': 'string',
          'company': 'string',
          'website': 'url',
          'message': 'text',
          'contact_reason': 'string',
          'newsletter_signup': 'boolean',
          'preferred_contact_method': 'string',
          'submission_date': 'date',
          'form_metadata': 'object',
        };

        expect(() => validator.validate(contactSchema), returnsNormally);

        final normalized = validator.validateAndNormalize(contactSchema);
        expect(normalized.length, equals(contactSchema.length));
      });
    });
  });
}
