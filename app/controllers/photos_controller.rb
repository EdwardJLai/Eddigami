class PhotosController < ApplicationController

  before_action :set_photo, only: [:show, :edit, :update, :destroy]

  #GET
  def index
    @sort = choice_assignment(:edited)
    @incidents = choice_assignment(:incident)
   
    if changed(:edited) || changed(:incident)
      session[:edited] = params[:edited]
      session[:incident] = params[:incident]
      redirect_to photos_path(:edited => @sort, :incident => @incidents) and return
    end
    photo_selector_logic
    @map_points = @photos.find_all{|x| x.lat != nil && x.lng != nil}
    index_logic
  end

  #GET
  def edit_queue
    redirect_to photos_path(:edited => 'false') and return
  end

  def index_logic
    @photo_pack = [[]]
    counter = 0
    pack_number = 0
    @bin_size = 3
    @photos.each do |photo|
      if counter == @bin_size
        counter = 0
        pack_number += 1
        @photo_pack[pack_number]=[]
      end
      @photo_pack[pack_number] << photo
      counter += 1
    end
  end

  def show
  end

  def new
    @photo = Photo.new
  end

  def edit
    @info = {:incident_name => @photo.incident_name,
    :taken_by => @photo.taken_by,
    :operational_period => @photo.operational_period,
    :team_number => @photo.team_number}
  end

  def create
    if params[:photo] and params[:photo][:image]
      @photo = make_photo
      if @photo.save
        redirect_to photo_path(@photo), notice: "Successfully created photo."
      else
        redirect_to new_photo_path(@photo), alert: "Couldn't save to database!"
      end
    else
      redirect_to new_photo_path(@photo), alert: "No files chosen!"
    end
  end
  
  #helper used by create and make_multiple
  def make_photo
    if params[:photo][:incident_name] == ""
      params[:photo][:incident_name] = "no incident name"
    end
    photo = Photo.new(photo_params)
    photo.edited = params[:photo][:edited] && params[:photo][:edited]=='1' ? true : false
    return photo
  end

  # PATCH/PUT /photos/1
  # PATCH/PUT /photos/1.json
  def update
    redirect_to photo_path(@photo), alert: "Couldn't update the photo." and return unless @photo.update_attributes(photo_params)

    @photo.rotate_image
    @photo.crop_image

    @photo.nullify_rotate_and_crop 
    if params[:photo][:edited]
      @photo.edited = params[:photo][:edited]=='1' ? true : false
    end
    @photo.save!
    redirect_to photo_path(@photo), notice: "Successfully updated photo."
  end

  # DELETE /photos/1
  # DELETE /photos/1.json
  def destroy
    @photo.destroy
    respond_to do |format|
      format.html { redirect_to photos_url }
      format.json { head :no_content }
    end
  end
  
  # GET
  def multiple_uploads
  end
  
  #POST
  def make_multiple
    redirect_to photos_multiple_uploads_path, alert: "No files chosen!" and return unless params[:photos] and params[:photos][:images]
    params[:photo] = params[:photos]
    params[:photos][:images].each do |photo|    
      params[:photo][:image] = photo
      redirect_to photos_multiple_uploads_path, alert: "Couldn't save photo!" and return unless make_photo.save
    end
    redirect_to photos_multiple_uploads_path, notice: "Multiple images uploaded"
  end
  
  def facebook_auth
    session["facebook_state"] = [params[:id], params[:comment]]
    redirect_to "/auth/facebook"      
  end

  def facebook_upload
    session["facebook_token"] = request.env['omniauth.auth']
    params[:id] = session["facebook_state"][0]
    set_photo
    token = session["facebook_token"]["credentials"]["token"]
    me = FbGraph::User.me(token)
    me.photo!(
      :source => open(@photo.image_url()),
      :message => session["facebook_state"][1]
    )
    session["facebook_state"] = nil
    redirect_to photo_path(@photo), notice: "Photo Uploaded to Facebook" and return
  end

  #GET
  def flickr_auth
    flickr = FlickRaw::Flickr.new
    flickr.access_token = session["flickr_access"]
    flickr.access_secret = session["flickr_secret"]
    begin
      flickr.test.login
    rescue
      session['flickr_authenticated']='false'
    end


    flickr_upload and return if session['flickr_authenticated'] == 'true'

    token = flickr.get_request_token
    @auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
    session['flickr_token']=token
  end

  #POST
  def flickr_upload
    set_photo

    return unless session['flickr_authenticated'] == 'true' || flickr_code_successful?
    
    flickr = FlickRaw::Flickr.new
    flickr.access_token = session["flickr_access"]
    flickr.access_secret = session["flickr_secret"]
    
    flickr.upload_photo @photo.image_url, :title => 'Title', :description => 'This is the description'
    redirect_to photo_path(@photo), notice: "Photo Uploaded to Flickr" and return
  end

  def flickr_code_successful?
    verify = params['code'].strip
    session['code'] = verify
    token = session['flickr_token']
    begin
      flickr = FlickRaw::Flickr.new
      
      flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
      session["flickr_access"] = flickr.access_token
      session["flickr_secret"] = flickr.access_secret
      flickr.test.login
      session['flickr_authenticated'] = 'true'
    rescue FlickRaw::OAuthClient::FailedResponse => e
      flash[:error] = "Authentication failed : #{e.message}"
      redirect_to photo_path(@photo), alert: "Authentication failed : #{e.message}"
      return false
    end
    return true
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_photo
    @photo = Photo.find(params[:id])
  end

  def changed(symbol)
    params[symbol] != session[symbol] 
  end

  def photo_selector_logic
    hash = {:edited => (@sort == 'true'), :incident_name => @incidents}
    @photos = Photo.where(@incidents == 'All' ? {:edited => hash[:edited]} : hash)
  end

  def choice_assignment(symbol)
    params[symbol] || session[symbol]
  end
  # Never trust parameters from the scary internet, only allow the white list through.
  def photo_params
    params.require(:photo).permit(:caption, :tags, :incident_name, :operational_period, :team_number, :taken_by, :time_taken, :image, :image_file, :crop_x, :crop_y, :crop_w, :crop_h, :rotation, :lng, :lat)
  end
end
