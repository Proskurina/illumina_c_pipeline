class CreationController < ApplicationController
  def create_form(form_attributes)
    form_lookup(form_attributes).new(form_attributes.merge(:api => api))
  end

  def new
    @creation_form = create_form(params.merge(:parent_uuid => params[:pulldown_plate_id]))

    respond_to do |format|
      # TODO Sort this look up out!
      format.html { render @creation_form.page }
    end
  end

  def create
    @creation_form = create_form(params[:plate])

    if @creation_form.save
      respond_to do |format|
        format.html { redirect_to redirection_path(@creation_form) }
      end
    else
      raise "Not saving #{@creation_form.class} form...."
    end
  end
end
