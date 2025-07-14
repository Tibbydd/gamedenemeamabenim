extends Node

# Memory and emotional system for CURSOR: Fragments of the Forgotten
signal memory_fragment_found
signal memory_reconstruction_complete
signal ethical_choice_made

# Memory fragment data structure
class MemoryFragment:
	var id: String
	var emotion_type: String
	var content: String
	var visual_data: Dictionary
	var corruption_level: float
	var connection_points: Array[String] = []
	var is_core_memory: bool = false
	var reconstruction_weight: float = 1.0
	
	func _init(fragment_id: String, emotion: String, memory_content: String):
		id = fragment_id
		emotion_type = emotion
		content = memory_content
		corruption_level = randf_range(0.1, 0.8)
		reconstruction_weight = randf_range(0.5, 2.0)

# Complete memory profile for a mind
class MindMemory:
	var mind_id: String
	var original_name: String
	var life_summary: String
	var primary_trauma: String
	var core_emotion: String
	var fragments: Array[MemoryFragment] = []
	var reconstruction_progress: float = 0.0
	var ethical_dilemma: Dictionary = {}
	
	func _init(id: String, name: String, emotion: String):
		mind_id = id
		original_name = name
		core_emotion = emotion

# Current session data
var current_mind: MindMemory
var collected_fragments: Array[MemoryFragment] = []
var reconstruction_sequences: Array[Array] = []

# Memory templates for generation
var memory_templates = {
	"regret": [
		"Bir fırsat kaçırıldı...",
		"Söylenmesi gereken sözler susturuldu...",
		"Geri alınamaz bir karar verildi...",
		"Son görüşme soğuk geçti..."
	],
	"anger": [
		"Adaletsizlik karşısında çaresizlik...",
		"İhanet anının acısı...",
		"Öfke kontrolden çıktı...",
		"Haksızlığa uğrama anı..."
	],
	"melancholy": [
		"Eski günlerin özlemi...",
		"Kayıp sevgilinin hatırası...",
		"Geçen zamanın ağırlığı...",
		"Yalnızlığın derinliği..."
	],
	"fear": [
		"Karanlıkta kaybolma korkusu...",
		"Terk edilme endişesi...",
		"Ölüm yaklaşırken hissedilen korku...",
		"Bilinmezlik karşısında titreme..."
	],
	"joy": [
		"İlk aşkın mutluluğu...",
		"Başarının verdiği gurur...",
		"Aile birlikteliğinin sıcaklığı...",
		"Hayallerin gerçekleşme anı..."
	],
	"trauma": [
		"Kırılma noktası...",
		"Her şeyin değiştiği an...",
		"Derin yaranın açıldığı gün...",
		"Güvenin sarsıldığı olay..."
	]
}

# Procedural memory generation
func generate_mind_memory(mind_profile: Dictionary) -> MindMemory:
	var emotion = mind_profile.primary_emotion
	var profession = mind_profile.get("profession", "unknown")
	var age = mind_profile.get("age_of_death", 50)
	
	# Generate basic mind info
	var mind_name = generate_random_name()
	var mind = MindMemory.new(
		str(randi_range(10000, 99999)), 
		mind_name, 
		emotion
	)
	
	# Generate life summary based on emotion and profession
	mind.life_summary = generate_life_summary(emotion, profession, age)
	mind.primary_trauma = generate_primary_trauma(emotion)
	
	# Generate memory fragments
	var fragment_count = mind_profile.get("memory_density", 20)
	for i in range(fragment_count):
		var fragment = generate_memory_fragment(emotion, profession, i)
		mind.fragments.append(fragment)
	
	# Mark some fragments as core memories
	mark_core_memories(mind)
	
	# Create ethical dilemma for end choice
	mind.ethical_dilemma = generate_ethical_dilemma(emotion, mind.primary_trauma)
	
	current_mind = mind
	return mind

func generate_random_name() -> String:
	var first_names = ["Ayşe", "Mehmet", "Fatma", "Ali", "Zeynep", "Mustafa", "Emine", "Ahmet", "Hatice", "Hüseyin"]
	var last_names = ["Yılmaz", "Kaya", "Demir", "Şahin", "Çelik", "Aydın", "Özkan", "Arslan", "Doğan", "Kilic"]
	
	return first_names[randi() % first_names.size()] + " " + last_names[randi() % last_names.size()]

func generate_life_summary(emotion: String, profession: String, age: int) -> String:
	var base_summary = "%d yaşında %s olarak yaşamını sürdüren bir birey. " % [age, profession]
	
	match emotion:
		"regret":
			return base_summary + "Hayatında aldığı kararlardan dolayı derin pişmanlıklar yaşadı."
		"anger":
			return base_summary + "Yaşadığı adaletsizlikler nedeniyle öfke dolu bir hayat geçirdi."
		"melancholy":
			return base_summary + "Melankolik bir ruh hali ile geçmişe özlem duyarak yaşadı."
		"fear":
			return base_summary + "Sürekli endişe ve korku içinde geçen bir yaşam sürdü."
		"joy":
			return base_summary + "Hayatın güzelliklerini keşfetmeyi seven neşeli bir kişiydi."
		"trauma":
			return base_summary + "Derin travmalar yaşayarak yaraları iyileşmemiş bir hayat geçirdi."
		_:
			return base_summary + "Sıradan ama anlamlı bir yaşam sürdü."

func generate_primary_trauma(emotion: String) -> String:
	match emotion:
		"regret":
			return "Sevdiği kişiye hislerini açamamak"
		"anger":
			return "Güvendiği birinin ihaneti"
		"melancholy":
			return "Çocukluk aşkının kaybı"
		"fear":
			return "Karanlıkta kaybolma deneyimi"
		"joy":
			return "Başarının kısa süreli olması"
		"trauma":
			return "Yakın birinin ani kaybı"
		_:
			return "Bilinmeyen bir olay"

func generate_memory_fragment(emotion: String, profession: String, index: int) -> MemoryFragment:
	var templates = memory_templates.get(emotion, ["Belirsiz bir anı..."])
	var content = templates[randi() % templates.size()]
	
	# Add profession-specific context
	content = add_profession_context(content, profession)
	
	var fragment = MemoryFragment.new(
		"fragment_" + str(index),
		emotion,
		content
	)
	
	# Set visual data for rendering
	fragment.visual_data = {
		"color_tint": GameManager.get_emotion_color(emotion),
		"glitch_intensity": fragment.corruption_level,
		"particle_type": get_emotion_particle_type(emotion)
	}
	
	return fragment

func add_profession_context(content: String, profession: String) -> String:
	match profession:
		"artist":
			return content + " (Sanat eserlerinde yansıyan...)"
		"scientist":
			return content + " (Laboratuvarda çalışırken...)"
		"teacher":
			return content + " (Öğrencilerle olan anıda...)"
		"engineer":
			return content + " (Teknik projeler arasında...)"
		"musician":
			return content + " (Müzik yaparken hissedilen...)"
		"writer":
			return content + " (Yazılarına yansıyan...)"
		"doctor":
			return content + " (Hasta bakımı sırasında...)"
		"architect":
			return content + " (Tasarım sürecinde yaşanan...)"
		_:
			return content

func get_emotion_particle_type(emotion: String) -> String:
	match emotion:
		"regret": return "falling_tears"
		"anger": return "red_sparks"
		"melancholy": return "blue_mist"
		"fear": return "dark_shadows"
		"joy": return "golden_light"
		"trauma": return "fragmented_glass"
		_: return "neutral_dots"

func mark_core_memories(mind: MindMemory) -> void:
	# Mark 3-5 random fragments as core memories
	var core_count = randi_range(3, 5)
	var selected_indices: Array[int] = []
	
	while selected_indices.size() < core_count and selected_indices.size() < mind.fragments.size():
		var index = randi() % mind.fragments.size()
		if index not in selected_indices:
			selected_indices.append(index)
			mind.fragments[index].is_core_memory = true
			mind.fragments[index].reconstruction_weight = 2.0

func generate_ethical_dilemma(emotion: String, trauma: String) -> Dictionary:
	var dilemma = {
		"title": "",
		"description": "",
		"choice_a": {
			"text": "",
			"consequence": ""
		},
		"choice_b": {
			"text": "",
			"consequence": ""
		}
	}
	
	match emotion:
		"regret":
			dilemma.title = "Pişmanlığın Yükü"
			dilemma.description = "Bu zihin pişmanlıklarla dolu. Onları silecek misin yoksa dünyayla paylaşacak mısın?"
			dilemma.choice_a.text = "Pişmanlıkları sil - Huzur ver"
			dilemma.choice_a.consequence = "Zihin huzurlu olacak ama deneyimler kaybolacak"
			dilemma.choice_b.text = "Anıları paylaş - Ders olsun"
			dilemma.choice_b.consequence = "Başkaları bu hatalardan öğrenecek"
		
		"anger":
			dilemma.title = "Öfkenin Ateşi"
			dilemma.description = "Bu zihin öfke ve adaletsizlik dolu. Bu emotions nasıl işlensin?"
			dilemma.choice_a.text = "Öfkeyi söndür - Sakinleştir"
			dilemma.choice_a.consequence = "Zihin sakin olacak ama adalet arayışı sona erecek"
			dilemma.choice_b.text = "Adaletsizlikleri açığa çıkar"
			dilemma.choice_b.consequence = "Gerçekler ortaya çıkacak ama acı sürecek"
		
		"trauma":
			dilemma.title = "Travmanın İzi"
			dilemma.description = "Derin travmalar bu zihni şekillendirmiş. Bu yaraları nasıl ele alacaksın?"
			dilemma.choice_a.text = "Travmayı sil - Ağrıyı bitir"
			dilemma.choice_a.consequence = "Acı sona erecek ama güçlenme deneyimi kaybolacak"
			dilemma.choice_b.text = "Travmayı iyileştir - Güç ver"
			dilemma.choice_b.consequence = "Zihin güçlenecek ve başkalarına yardım edebilecek"
		
		_:
			dilemma.title = "Hafızanın Seçimi"
			dilemma.description = "Bu zihinle ne yapılacağına karar ver."
			dilemma.choice_a.text = "Anıları muhafaza et"
			dilemma.choice_a.consequence = "Geçmiş korunacak"
			dilemma.choice_b.text = "Yeni başlangıç ver"
			dilemma.choice_b.consequence = "Temiz sayfa açılacak"
	
	return dilemma

func collect_fragment(fragment_id: String) -> MemoryFragment:
	if not current_mind:
		return null
	
	# Find fragment in current mind
	for fragment in current_mind.fragments:
		if fragment.id == fragment_id:
			if fragment not in collected_fragments:
				collected_fragments.append(fragment)
				update_reconstruction_progress()
				memory_fragment_found.emit()
				return fragment
	
	return null

func update_reconstruction_progress() -> void:
	if not current_mind:
		return
	
	var total_weight = 0.0
	var collected_weight = 0.0
	
	# Calculate total possible weight
	for fragment in current_mind.fragments:
		total_weight += fragment.reconstruction_weight
	
	# Calculate collected weight
	for fragment in collected_fragments:
		collected_weight += fragment.reconstruction_weight
	
	current_mind.reconstruction_progress = collected_weight / total_weight
	
	# Check if reconstruction is complete (80% threshold)
	if current_mind.reconstruction_progress >= 0.8:
		complete_memory_reconstruction()

func complete_memory_reconstruction() -> void:
	print("Memory reconstruction complete!")
	memory_reconstruction_complete.emit()

func get_reconstruction_sequences() -> Array[Array]:
	# Create logical sequences of connected memories
	var sequences: Array[Array] = []
	var processed_fragments: Array[MemoryFragment] = []
	
	for fragment in collected_fragments:
		if fragment in processed_fragments:
			continue
		
		var sequence: Array[MemoryFragment] = [fragment]
		processed_fragments.append(fragment)
		
		# Find connected fragments
		find_connected_fragments(fragment, sequence, processed_fragments)
		
		if sequence.size() > 1:
			sequences.append(sequence)
	
	return sequences

func find_connected_fragments(base_fragment: MemoryFragment, sequence: Array, processed: Array) -> void:
	for fragment in collected_fragments:
		if fragment in processed:
			continue
		
		# Check if fragments are emotionally connected
		if are_fragments_connected(base_fragment, fragment):
			sequence.append(fragment)
			processed.append(fragment)
			# Recursively find more connections
			find_connected_fragments(fragment, sequence, processed)

func are_fragments_connected(frag_a: MemoryFragment, frag_b: MemoryFragment) -> bool:
	# Simple connection logic - same emotion type or low corruption difference
	return (frag_a.emotion_type == frag_b.emotion_type or 
			abs(frag_a.corruption_level - frag_b.corruption_level) < 0.3)

func make_ethical_choice(choice: String) -> void:
	if not current_mind:
		return
	
	print("Ethical choice made: ", choice)
	ethical_choice_made.emit()
	
	# This choice affects the game's narrative ending
	# Implementation would depend on the specific choice system

func get_current_mind() -> MindMemory:
	return current_mind

func get_collected_fragments() -> Array[MemoryFragment]:
	return collected_fragments

func get_fragment_by_id(fragment_id: String) -> MemoryFragment:
	for fragment in collected_fragments:
		if fragment.id == fragment_id:
			return fragment
	return null

func reset_collection() -> void:
	collected_fragments.clear()
	current_mind = null

func get_reconstructed_memory_summary() -> Dictionary:
	# Get summary of reconstructed memories for ethical choices
	if collected_fragments.is_empty():
		return {
			"owner_name": "Bilinmeyen Kişi",
			"age": "Belirsiz",
			"profession": "Bilinmeyen",
			"dominant_emotion": "neutral"
		}
	
	# Analyze collected fragments to create summary
	var professions = {}
	var emotions = {}
	var ages = []
	
	for fragment in collected_fragments:
		var memory_data = fragment.content_preview
		# Extract info from memory text (simple keyword matching)
		if "doktor" in memory_data or "hastane" in memory_data:
			professions["doctor"] = professions.get("doctor", 0) + 1
		elif "öğretmen" in memory_data or "okul" in memory_data:
			professions["teacher"] = professions.get("teacher", 0) + 1
		elif "mühendis" in memory_data or "inşaat" in memory_data:
			professions["engineer"] = professions.get("engineer", 0) + 1
		elif "sanat" in memory_data or "müzik" in memory_data:
			professions["artist"] = professions.get("artist", 0) + 1
		else:
			professions["worker"] = professions.get("worker", 0) + 1
		
		# Emotion analysis from fragment type
		emotions[fragment.emotion_resonance] = emotions.get(fragment.emotion_resonance, 0) + 1
		ages.append(randi_range(40, 80))  # Estimate age from content
	
	# Find most common profession and emotion
	var dominant_profession = "worker"
	var max_prof_count = 0
	for prof in professions:
		if professions[prof] > max_prof_count:
			max_prof_count = professions[prof]
			dominant_profession = prof
	
	var dominant_emotion = "neutral"
	var max_emotion_count = 0
	for emotion in emotions:
		if emotions[emotion] > max_emotion_count:
			max_emotion_count = emotions[emotion]
			dominant_emotion = emotion
	
	# Calculate average age
	var avg_age = 50
	if ages.size() > 0:
		var total = 0
		for age in ages:
			total += age
		avg_age = total / ages.size()
	
	# Generate name based on profession and emotion
	var names = {
		"doctor": ["Dr. Mehmet Yılmaz", "Dr. Ayşe Demir", "Dr. Mustafa Kaya"],
		"teacher": ["Öğretmen Fatma", "Hocam Ali", "Müdür Zeynep"],
		"engineer": ["Mühendis Ahmet", "İnşaatçı Hasan", "Tekniker Sevim"],
		"artist": ["Sanatçı Leyla", "Ressam Kemal", "Müzisyen Deniz"],
		"worker": ["İşçi Osman", "Usta Veli", "Tamirci Hacer"]
	}
	
	var name_list = names.get(dominant_profession, ["Bilinmeyen Kişi"])
	var selected_name = name_list[randi() % name_list.size()]
	
	return {
		"owner_name": selected_name,
		"age": str(avg_age),
		"profession": dominant_profession,
		"dominant_emotion": dominant_emotion,
		"fragments_count": collected_fragments.size()
	}