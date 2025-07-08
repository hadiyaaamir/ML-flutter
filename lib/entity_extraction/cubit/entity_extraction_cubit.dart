import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:ml_flutter/common/common.dart';
import '../models/extracted_entity.dart';

part 'entity_extraction_state.dart';

class EntityExtractionCubit extends Cubit<EntityExtractionState> {
  EntityExtractionCubit() : super(const EntityExtractionState());

  EntityExtractor? _entityExtractor;

  Future<void> extractEntities(String text) async {
    if (text.trim().isEmpty) {
      emit(
        state.copyWith(
          inputText: text,
          entityExtractionDataState: const DataState.failure(
            error: 'Please enter some text to extract entities',
          ),
        ),
      );
      return;
    }

    // Clear any previous error and start loading
    emit(
      state.copyWith(
        inputText: text,
        entityExtractionDataState: state.entityExtractionDataState.toLoading(),
      ),
    );

    try {
      // Initialize entity extractor if not already done
      _entityExtractor ??= EntityExtractor(
        language: EntityExtractorLanguage.english,
      );

      // Extract entities from text using annotateText
      final annotations = await _entityExtractor!.annotateText(text);

      // Convert ML Kit annotations to our custom model
      final extractedEntities = <ExtractedEntity>[];

      for (final annotation in annotations) {
        for (final entity in annotation.entities) {
          extractedEntities.add(
            ExtractedEntity(
              text: annotation.text,
              type: _getEntityTypeName(entity.type),
              startIndex: annotation.start,
              endIndex: annotation.end,
            ),
          );
        }
      }

      if (extractedEntities.isEmpty) {
        emit(
          state.copyWith(
            entityExtractionDataState: const DataState.failure(
              error: 'No entities found in the text',
            ),
          ),
        );
      } else {
        emit(
          state.copyWith(
            entityExtractionDataState: DataState.loaded(
              data: extractedEntities,
            ),
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          entityExtractionDataState: DataState.failure(
            error: 'Error extracting entities: ${e.toString()}',
          ),
        ),
      );
    }
  }

  String _getEntityTypeName(EntityType type) {
    switch (type) {
      case EntityType.address:
        return 'Address';
      case EntityType.dateTime:
        return 'Date/Time';
      case EntityType.email:
        return 'Email';
      case EntityType.flightNumber:
        return 'Flight Number';
      case EntityType.iban:
        return 'IBAN';
      case EntityType.isbn:
        return 'ISBN';
      case EntityType.paymentCard:
        return 'Payment Card';
      case EntityType.phone:
        return 'Phone Number';
      case EntityType.trackingNumber:
        return 'Tracking Number';
      case EntityType.url:
        return 'URL';
      case EntityType.money:
        return 'Money';
      case EntityType.unknown:
        return 'Unknown';
    }
  }

  void clearResults() {
    emit(const EntityExtractionState());
  }

  @override
  Future<void> close() {
    _entityExtractor?.close();
    return super.close();
  }
}
