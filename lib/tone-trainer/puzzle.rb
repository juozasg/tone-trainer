module ToneTrainer
    class Puzzle
        include ToneTrainer::Nomenclature

        attr_reader :stats_good, :stats_bad, :difficulty, :length, :root
        attr_accessor :score

        def initialize(difficulty, length, root, midi)
            @difficulty = difficulty
            @length = length
            @root = root
            @midi = midi

            @score = difficulty * length

            @correct_length = 0

            @seq = generate_seq

            @note_duration = 0.7
            @rest_duration = 0.2

            # interval => count
            @stats_good = {}
            @stats_bad = {}
        end

        def generate_seq
            selected_intervals = '{' + INTERVALS[0...@difficulty].join(', ') + '}'
            puts "#{selected_intervals} ".blue + "x#{@length}".magenta.italic.blink + "  (#{@score.to_s.green} pts)"
            
            pool = SEMITONES[0...@difficulty]
            seq = [0]
            (@length - 2).times do
                sample = pool.sample
                if sample == @root && rand > 0.5
                    # avoid too many roots
                    sample = pool.sample
                end
                seq << sample
            end
            seq << 0
        end

        def replay(sound = true)
            @correct_length = 0

            prompt(sound)
        end
        
        def prompt(sound = true, wrong_note = false)
            @seq.each_with_index do |st, i|
                note_code = @root + st
                note_name = note_name(note_code)
                tname = tone_name(note_name)

                if i < @correct_length
                    print_answered tname
                elsif wrong_note && i == @correct_length
                    print_wrong(wrong_note)
                elsif i == @seq.length - 1 || i == 0
                    # first and last one is known to be root
                    print_unanswered tname, i == @correct_length
                else
                    print_unanswered '?', i == @correct_length
                end

                if sound
                    @midi.play note_code, @note_duration
                    sleep @rest_duration unless i == @seq.length - 1
                end
            end
      
            puts ""
        end

        def print_answer(green = false)
            names = @seq.map do |st|
                note_code = @root + st
                note_name = note_name(note_code)
                tone_name(note_name)
            end
            names = names.join(' ')
            if green
                puts names.green
            else
                puts names.yellow
            end
        end


        def guess!(semitone)
            if @seq[@correct_length] == semitone
                # dont count first and last root notes in stats
                unless @correct_length == 0 || @correct_length == @seq.length - 1
                    @stats_good[semitone] ||= 0
                    @stats_good[semitone] += 1
                end
                @correct_length += 1
                return true
            else
                @stats_bad[semitone] ||= 0
                @stats_bad[semitone] += 1
                return false
            end
        end

        def solved?
            @correct_length == @seq.length
        end

        private
        def print_answered(str)
            print str.green + ' '
            $stdout.flush
        end

        def print_wrong(str)
            print str.red + ' '
            $stdout.flush
        end

        def print_unanswered(str, blink = false)
            if blink
                str = str.light_yellow.on_black.blink
            else
                str = str.light_yellow
            end
            print str + ' '
            $stdout.flush
        end
    end
end