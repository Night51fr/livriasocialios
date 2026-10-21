import SwiftUI

// MARK: - Onglet 4 : Espace Jeux de Livria (Bonus Quotidien, Roue de la Fortune, Quiz Littéraire & Mot Mystère)

public struct SocialGamesHubView: View {
    @EnvironmentObject private var social: LivriaSocialViewModel

    @State private var selectedGameSection: Int = 0 // 0 = Roue & Bonus, 1 = Quiz Littéraire, 2 = Mot Mystère
    @State private var wheelRotation: Double = 0
    @State private var isSpinningWheel: Bool = false
    @State private var lastWheelPrize: String? = nil

    // Quiz Littéraire
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var quizScore: Int = 0
    @State private var quizFinished: Bool = false

    // Mot Mystère
    @State private var currentWordIndex: Int = 0
    @State private var wordGuess: String = ""
    @State private var wordFeedback: String? = nil

    private let quizQuestions = SocialQuizQuestionItem.sampleQuestions
    private let scrambleWords = SocialWordScrambleItem.all

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    gamesHeroCard

                    SocialSegmentedPillBar(
                        items: [
                            (0, "Roue & Bonus", "sparkles"),
                            (1, "Quiz XP", "brain.head.profile"),
                            (2, "Mot Mystère", "textformat.abc")
                        ],
                        selection: $selectedGameSection
                    )

                    if selectedGameSection == 0 {
                        dailyBonusAndWheelSection
                    } else if selectedGameSection == 1 {
                        literaryQuizSection
                    } else {
                        wordScrambleSection
                    }

                    rewardsAndRulesCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .socialCustomBackground(
                type: social.currentUser?.pageBackgroundType,
                value: social.currentUser?.pageBackgroundValue
            )
            .navigationTitle("Espace Jeux Livria")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await social.refreshBootstrap()
            }
        }
    }

    // MARK: - En-tête XP, Niveau & Série Quotidienne

    private var gamesHeroCard: some View {
        let xp = social.games?.xpPoints ?? social.currentUser?.xpPoints ?? 120
        let level = social.games?.level ?? social.currentUser?.level ?? 1
        let streak = social.games?.dailyStreak ?? 1
        let wallet = social.games?.affiliateBalanceEur ?? social.currentUser?.affiliateBalanceEur ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("ARCADE LITTÉRAIRE LIVRIA", systemImage: "gamecontroller.fill")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(LivriaSocialPalette.goldGradient))

                Spacer()

                Text("🔥 Série : \(streak) j")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LivriaSocialPalette.gold)
            }

            HStack(spacing: 14) {
                statPill(title: "NIVEAU", value: "Niv. \(level)", color: LivriaSocialPalette.primary)
                statPill(title: "EXPÉRIENCE", value: "\(xp) XP", color: LivriaSocialPalette.accent)
                statPill(title: "CAGNOTTE", value: String(format: "%.2f €", wallet), color: LivriaSocialPalette.emerald)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#2E1065"), Color(hex: "#0F172A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(LivriaSocialPalette.primary.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private func statPill(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(LivriaSocialPalette.textMuted)
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Section 0 : Bonus Quotidien & Roue de la Fortune

    private var dailyBonusAndWheelSection: some View {
        let canClaimDaily = social.games?.canClaimDaily ?? true
        let canSpinWheel = social.games?.canSpinWheel ?? true

        return VStack(spacing: 16) {
            // Bonus Quotidien
            HStack(spacing: 14) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(LivriaSocialPalette.gold)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(LivriaSocialPalette.gold.opacity(0.16)))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Bonus Quotidien de Lecture")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Réclamez votre coffre chaque jour pour augmenter votre série et gagner jusqu'à +60 XP.")
                        .font(.system(size: 12))
                        .foregroundStyle(LivriaSocialPalette.textMuted)
                }

                Spacer()

                Button {
                    Task { await social.claimDailyGameBonus() }
                } label: {
                    Text(canClaimDaily ? "Réclamer" : "Reçu ✓")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(canClaimDaily ? LivriaSocialPalette.ink : .white.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(
                                canClaimDaily
                                    ? AnyShapeStyle(LivriaSocialPalette.goldGradient)
                                    : AnyShapeStyle(Color.white.opacity(0.08))
                            )
                        )
                }
                .disabled(!canClaimDaily)
            }
            .padding(16)
            .socialCard()

            // Roue de la Fortune Littéraire
            VStack(spacing: 16) {
                Text("🎡 Roue de la Fortune Livria")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("1 lancer gratuit par jour : tentez de remporter des XP ou des bonus en euros crédités sur votre cagnotte Livria !")
                    .font(.system(size: 12))
                    .foregroundStyle(LivriaSocialPalette.textMuted)
                    .multilineTextAlignment(.center)

                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    LivriaSocialPalette.primary,
                                    LivriaSocialPalette.secondary,
                                    LivriaSocialPalette.gold,
                                    LivriaSocialPalette.emerald,
                                    LivriaSocialPalette.accent,
                                    LivriaSocialPalette.primary
                                ],
                                center: .center
                            )
                        )
                        .frame(width: 190, height: 190)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 4)
                        )
                        .rotationEffect(.degrees(wheelRotation))

                    Circle()
                        .fill(LivriaSocialPalette.ink)
                        .frame(width: 68, height: 68)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 26, weight: .black))
                                .foregroundStyle(LivriaSocialPalette.gold)
                        )
                }
                .padding(.vertical, 6)

                if let prize = lastWheelPrize {
                    Text("🎉 Résultat : \(prize)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(LivriaSocialPalette.gold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(LivriaSocialPalette.gold.opacity(0.15)))
                }

                Button {
                    guard !isSpinningWheel else { return }
                    isSpinningWheel = true
                    withAnimation(.easeOut(duration: 1.8)) {
                        wheelRotation += 1080 + Double(Int.random(in: 45...315))
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        let reward = await social.spinFortuneWheel()
                        lastWheelPrize = reward
                        isSpinningWheel = false
                    }
                } label: {
                    Label(
                        canSpinWheel ? "Tourner la Roue Gratuite" : "Déjà tournée aujourd'hui",
                        systemImage: "arrow.triangle.2.circlepath.circle.fill"
                    )
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        Capsule().fill(
                            canSpinWheel
                                ? AnyShapeStyle(LivriaSocialPalette.brandGradient)
                                : AnyShapeStyle(Color.white.opacity(0.10))
                        )
                    )
                }
                .disabled(!canSpinWheel || isSpinningWheel)
            }
            .padding(18)
            .socialCard()
        }
    }

    // MARK: - Section 1 : Quiz Littéraire

    private var literaryQuizSection: some View {
        let question = quizQuestions[currentQuestionIndex % quizQuestions.count]

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🧠 Quiz Culture & Littérature")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("Question \(currentQuestionIndex + 1)/\(quizQuestions.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LivriaSocialPalette.gold)
            }

            if quizFinished {
                VStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 46))
                        .foregroundStyle(LivriaSocialPalette.gold)

                    Text("Score final : \(quizScore) / \(quizQuestions.count)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Button {
                        currentQuestionIndex = 0
                        selectedOptionIndex = nil
                        quizScore = 0
                        quizFinished = false
                    } label: {
                        Label("Rejouer une manche", systemImage: "arrow.clockwise")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(LivriaSocialPalette.ink)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(LivriaSocialPalette.goldGradient))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            } else {
                Text(question.question)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)

                ForEach(Array(question.options.enumerated()), id: \.offset) { idx, opt in
                    let isChosen = selectedOptionIndex == idx
                    let isCorrect = idx == question.correctIndex

                    Button {
                        guard selectedOptionIndex == nil else { return }
                        selectedOptionIndex = idx
                        if isCorrect {
                            quizScore += 1
                        }
                    } label: {
                        HStack {
                            Text(opt)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            if selectedOptionIndex != nil {
                                if isCorrect {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(LivriaSocialPalette.emerald)
                                } else if isChosen {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(LivriaSocialPalette.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    selectedOptionIndex == nil
                                        ? Color.white.opacity(0.06)
                                        : (isCorrect ? LivriaSocialPalette.emerald.opacity(0.22) : (isChosen ? LivriaSocialPalette.secondary.opacity(0.22) : Color.white.opacity(0.04)))
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                if selectedOptionIndex != nil {
                    Text(question.aneckdote)
                        .font(.system(size: 12))
                        .foregroundStyle(LivriaSocialPalette.gold)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(LivriaSocialPalette.gold.opacity(0.10)))

                    Button {
                        if currentQuestionIndex + 1 < quizQuestions.count {
                            currentQuestionIndex += 1
                            selectedOptionIndex = nil
                        } else {
                            quizFinished = true
                            let earnedXp = max(10, quizScore * 15)
                            Task {
                                await social.submitGameScore(game: "Quiz Littéraire", score: quizScore, xp: earnedXp)
                            }
                        }
                    } label: {
                        Text(currentQuestionIndex + 1 < quizQuestions.count ? "Question suivante →" : "Valider mon score (+\(max(10, quizScore * 15)) XP)")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Capsule().fill(LivriaSocialPalette.brandGradient))
                    }
                }
            }
        }
        .padding(16)
        .socialCard()
    }

    // MARK: - Section 2 : Mot Mystère Littéraire

    private var wordScrambleSection: some View {
        let item = scrambleWords[currentWordIndex % scrambleWords.count]

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🔤 Mot Mystère Littéraire")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("+25 XP / mot")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(LivriaSocialPalette.emerald)
            }

            Text("Remettez les lettres dans l'ordre :")
                .font(.system(size: 12))
                .foregroundStyle(LivriaSocialPalette.textMuted)

            Text(item.scrambled)
                .font(.system(size: 26, weight: .black, design: .monospaced))
                .foregroundStyle(LivriaSocialPalette.gold)
                .tracking(4)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )

            Text("💡 Indice : \(item.hint)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))

            HStack(spacing: 10) {
                TextField("Votre réponse...", text: $wordGuess)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(11)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                    .foregroundStyle(.white)

                Button {
                    let clean = wordGuess.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    if clean == item.answer {
                        wordFeedback = "✅ Bravo ! Le mot était bien \(item.answer) (+25 XP)."
                        wordGuess = ""
                        currentWordIndex = (currentWordIndex + 1) % scrambleWords.count
                        Task {
                            await social.submitGameScore(game: "Mot Mystère", score: 100, xp: 25)
                        }
                    } else {
                        wordFeedback = "❌ Ce n'est pas tout à fait ça, essayez encore !"
                    }
                } label: {
                    Text("Valider")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(LivriaSocialPalette.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(LivriaSocialPalette.goldGradient))
                }
            }

            if let feedback = wordFeedback {
                Text(feedback)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(feedback.hasPrefix("✅") ? LivriaSocialPalette.emerald : LivriaSocialPalette.secondary)
            }
        }
        .padding(16)
        .socialCard()
    }

    // MARK: - Barème des Gains XP & Euros

    private var rewardsAndRulesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🏆 BARÈME D'EXPÉRIENCE LIVRIA SOCIAL")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(LivriaSocialPalette.gold)

            Text("• Chaque tranche de 120 XP fait monter votre Niveau de Lecteur.\n• Les bonus en centimes gagnés sur la Roue de la Fortune s'ajoutent directement à votre cagnotte affiliée Livria Store.\n• Publier un post (+15 XP), commenter (+5 XP) ou créer une liste (+25 XP) accélère votre progression.")
                .font(.system(size: 12))
                .foregroundStyle(LivriaSocialPalette.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .socialCard()
    }
}
