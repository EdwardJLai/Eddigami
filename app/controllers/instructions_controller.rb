class InstructionsController < ApplicationController

	def new
		render layout: "photos"
	end
	
	def show
		@inst = Instruction.find(params[:id])
		render layout: "photos"
	end
	
	def create
		@inst = Instruction.create!(inst_params)
		@inst.has_image = params[:instruction][:cover] != nil ? true : false
		debugger
		redirect_to instruction_path(@inst), notice: "Successfully created new instruction."
	end
	
	def index
		@inst = Instruction.all
		@instruction_pack = [[]]
    counter = 0
    pack_number = 0
    @bin_size = 4
    @inst.each do |inst|
      if counter == @bin_size
        counter = 0
        pack_number += 1
        @instruction_pack[pack_number]=[]
      end
      @instruction_pack[pack_number] << inst
      counter += 1
    end
    #debugger
    render layout: "photos"
	end
	
	def destroy
		#debugger
		@inst = Instruction.find(params[:id])
		@inst.destroy
		redirect_to instructions_path, notice: "Successfully deleted instruction"
	end
	
	private
	
	def inst_params
    params.require(:instruction).permit(:name, :description, :cover, :date, :who)
  end
	
end
