class TestPassage < ApplicationRecord
  SUCCESS_RATIO = 85

  belongs_to :user
  belongs_to :test
  belongs_to :current_question, class_name: "Question", optional: true

  before_validation :set_current_question
  before_update     :check_test_finish

  scope :successful, -> { where(successful: true) }

  def time_left
    (test.time_limit * 15) - (Time.current - created_at).to_i
  end

  def accept!(answer_ids:)
    self.correct_questions += 1 if correct_answer?(answer_ids)
    self.successful = true if complete_successful?

    save!
  end

  def completed?
    current_question.nil?
  end

  def percent_correct_answers
    ((correct_questions.fdiv test.questions.count) * 100).round
  end

  def complete_successful?
    percent_correct_answers >= SUCCESS_RATIO
  end

  def number_current_question
    test.questions.order(:id).where('id < ?', current_question_id).count + 1
  end

  private

  def check_test_finish
    self.current_question = nil if time_left <= 0
  end

  def set_current_question
    self.current_question = next_question
  end

  def correct_answer?(answer_ids)
    return false if answer_ids.nil?

    correct_answers.ids.sort == answer_ids.map(&:to_i).sort
  end

  def correct_answers
    current_question.answers.correct
  end

  def next_question
    if current_question.nil? && test.present?
      test.questions.order(:id).first
    else
      test.questions.order(:id).where('id > ?', current_question.id).first
    end
  end
end
