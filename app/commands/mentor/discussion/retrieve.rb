module Mentor
  class Discussion
    class Retrieve
      include Mandate

      REQUESTS_PER_PAGE = 10
      STATUSES = %i[all awaiting_mentor awaiting_student finished].freeze

      def self.requests_per_page
        REQUESTS_PER_PAGE
      end

      def initialize(mentor,
                     status,
                     page: nil,
                     student_handle: nil,
                     criteria: nil, order: nil,
                     track_slug: nil,
                     sorted: true, paginated: true)

        # This will be a code-level exception rather than a user-level
        # exception so we don't worry about a special class. Getting this
        # tells us that we've got a bug.
        raise "Invalid status: #{status}" unless STATUSES.include?(status.to_sym)

        @mentor = mentor
        @status = status.to_sym
        @page = page || 1
        @student_handle = student_handle
        @track_slug = track_slug
        @criteria = criteria
        @order = order

        @sorted = sorted
        @paginated = paginated
      end

      def call
        setup!
        filter_status!
        filter_track!
        filter_student!
        search!
        sort! if sorted?
        paginate! if paginated?

        @discussions
      end

      private
      attr_reader :mentor, :status, :page, :student_handle, :track_slug, :criteria, :order

      %i[sorted paginated].each do |attr|
        define_method("#{attr}?") { instance_variable_get("@#{attr}") }
      end

      def setup!
        @discussions = Mentor::Discussion.
          joins(solution: :exercise).
          includes(solution: [:user, { exercise: :track }]).
          where(mentor: mentor)
      end

      def filter_status!
        case status
        when :awaiting_mentor
          @discussions = @discussions.awaiting_mentor
        when :awaiting_student
          @discussions = @discussions.awaiting_student
        when :finished
          @discussions = @discussions.finished_for_mentor
        end
      end

      # TODO: (Optional) This is just a stub implementation
      def filter_track!
        return if track_slug.blank?

        @discussions = @discussions.where(tracks: { slug: track_slug })
      end

      def filter_student!
        return if student_handle.blank?

        student_id = User.where(handle: student_handle.strip).pick(:id)
        return unless student_id

        @discussions = @discussions.where(solutions: { user_id: student_id })
      end

      def search!
        return if criteria.blank?

        @discussions = @discussions.joins(solution: :user).
          where("exercises.title LIKE ? OR users.handle LIKE ?", "%#{criteria}%", "%#{criteria}%")
      end

      def sort!
        case order
        when "exercise"
          @discussions = @discussions.order("exercises.title": :asc, id: :asc)
        when "student"
          @discussions = @discussions.joins(solution: :user).order("users.handle": :asc, id: :asc)
        when 'recent'
          @discussions = @discussions.order(updated_at: :desc, id: :desc)
        else
          @discussions = @discussions.order(updated_at: :asc, id: :asc)
        end
      end

      def paginate!
        @discussions = @discussions.page(page).per(self.class.requests_per_page)
      end
    end
  end
end
