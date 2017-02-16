module Helpers
  def four_oh_four
    res.status = 404
    res.write 'not found'

    halt(res.finish)
  end
end
