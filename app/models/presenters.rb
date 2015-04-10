module Presenters
  module Presenter
    def self.included(base)
      base.class_eval do
        include Forms::Form
        write_inheritable_attribute :page, 'show'

        class_inheritable_reader :has_qc_data?
        write_inheritable_attribute :has_qc_data?, false
      end
    end

    def save!
    end

    def default_printer_uuid
      @default_printer_uuid ||= Settings.purposes[purpose.uuid].default_printer_uuid
    end

    def label_type
      nil
    end

  end

  class PlatePresenter
    include Presenter
    include Commentable::Commented
    include PlateWalking

    class_inheritable_reader :labware_class
    write_inheritable_attribute :labware_class, :plate

    class_inheritable_reader :child_type
    write_inheritable_attribute :child_type, 'plate'

    write_inheritable_attribute :attributes, [ :api, :labware ]

    class_inheritable_reader    :aliquot_partial
    write_inheritable_attribute :aliquot_partial, 'labware/aliquot'

    class_inheritable_reader    :summary_partial
    write_inheritable_attribute :summary_partial, 'labware/plates/standard_summary'

    class_inheritable_reader    :additional_creation_partial
    write_inheritable_attribute :additional_creation_partial, 'labware/plates/child_plate_creation'

    class_inheritable_reader :printing_partial

    class_inheritable_reader    :tab_views
    write_inheritable_attribute :tab_views, {
      'labware-summary-button'  => [ 'labware-summary', 'plate-printing' ],
      'labware-creation-button' => [ 'labware-summary', 'plate-creation' ],
      'labware-QC-button'       => [ 'labware-summary', 'plate-creation' ],
      'labware-state-button'    => [ 'labware-summary', 'plate-state'    ],
      'well-failing-button'     => [ 'well-failing', 'well-failing-instructions' ]
    }

    # This is now generated dynamically by the LabwareHelper
    class_inheritable_reader    :tab_states

    class_inheritable_reader :robot_name

    class_inheritable_reader    :authenticated_tab_states
    write_inheritable_attribute :authenticated_tab_states, {
        :pending    =>  [ 'labware-summary-button', 'labware-state-button'                           ],
        :started    =>  [ 'labware-state-button', 'labware-summary-button'                           ],
        :passed     =>  [ 'labware-creation-button', 'labware-state-button', 'labware-summary-button' ],
        :cancelled  =>  [ 'labware-summary-button' ],
        :failed     =>  [ 'labware-summary-button' ]
    }

    def plate_to_walk
      self.labware
    end

    def label_type
      yield "custom-labels"
    end

    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    def purpose
      labware.plate_purpose
    end

    def allow_plate_label_printing?; true end

    def label_text
      "#{labware.label.prefix} #{labware.label.text}"
    end

    def location
      Settings.locations[labware.location]
    end

    def control_worksheet_printing(&block)
      yield
      nil
    end

    def labware_form_details(view)
      { :url => view.illumina_c_plate_path(self.labware), :as  => :plate }
    end

    def transfers
      transfers = self.labware.creation_transfer.transfers
      transfers.sort {|a,b| split_location(a.first) <=> split_location(b.first) }
    end

    def qc_owner
      labware
    end

    def has_repeated_tag?
      false
    end



    # Split a location string into an array containing the row letter
    # and the column number (as a integer) so that they can be sorted.
    def split_location(location_string)
      match = location_string.match(/^([A-H])(\d+)/)
      [ match[2].to_i, match[1] ]  # Order by column first
    end
    private :split_location

    class UnknownPlateType < StandardError
      attr_reader :plate

      def initialize(plate)
        super("Unknown plate type #{plate.plate_purpose.name.inspect}")
        @plate = plate
      end
    end

    def self.lookup_for(labware)
      presentation_classes = Settings.purposes[labware.plate_purpose.uuid] or raise UnknownPlateType, labware
      presentation_classes[:presenter_class].constantize
    end
  end
end
