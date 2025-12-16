//+------------------------------------------------------------------+
//|                                        C_HarmonicRecognizer.mqh |
//|          Harmonic Pattern Detection Class for EA Integration     |
//|            Converted from HarmonicPatternFinder.mq5 logic        |
//+------------------------------------------------------------------+
#ifndef LULA_HARMONIC_RECOGNIZER_MQH
#define LULA_HARMONIC_RECOGNIZER_MQH

#include "Lula_CoreEnums.mqh"

//+------------------------------------------------------------------+
//| Fibonacci ratio descriptor for harmonic patterns                  |
//+------------------------------------------------------------------+
struct HarmonicRatios
  {
   double            ab2xa_min, ab2xa_max;   // AB/XA ratio range
   double            bc2ab_min, bc2ab_max;   // BC/AB ratio range
   double            cd2bc_min, cd2bc_max;   // CD/BC ratio range
   double            ad2xa_min, ad2xa_max;   // AD/XA ratio range
   double            cd2xc_min, cd2xc_max;   // CD/XC ratio range (for Cypher, Shark)
   double            xc2xa_min, xc2xa_max;   // XC/XA ratio range (for Cypher, Nen Star)
  };

//+------------------------------------------------------------------+
//| Detected harmonic pattern result                                  |
//+------------------------------------------------------------------+
struct HarmonicPatternResult
  {
   ENUM_HARMONIC_PATTERN type;
   bool               isBullish;
   double             X, A, B, C, D;
   datetime           XTime, ATime, BTime, CTime, DTime;
   double             prz_high;      // Potential Reversal Zone high
   double             prz_low;       // Potential Reversal Zone low
   double             confidence;    // Pattern quality score 0.0-1.0
   string             patternName;
  };

//+------------------------------------------------------------------+
//| Harmonic Pattern Recognizer Class                                 |
//| Detects Fibonacci-based harmonic patterns from swing points       |
//+------------------------------------------------------------------+
class C_HarmonicRecognizer
  {
private:
   HarmonicRatios    m_patterns[];
   string            m_patternNames[];
   int               m_numPatterns;
   double            m_slackRange;     // Tolerance for ratio ranges
   double            m_slackUnary;     // Tolerance for exact ratios

public:
   //--- Constructor
   C_HarmonicRecognizer(void)
     {
      m_numPatterns = 0;
      m_slackRange = 0.01;
      m_slackUnary = 0.1;
     }

   //--- Destructor
   ~C_HarmonicRecognizer(void)
     {
      ArrayFree(m_patterns);
      ArrayFree(m_patternNames);
     }

   //--- Initialize with Fibonacci ratio tolerances
   bool Initialize(double slackRange = 0.01, double slackUnary = 0.1)
     {
      m_slackRange = slackRange;
      m_slackUnary = slackUnary;
      
      PopulatePatterns();
      return true;
     }

   //--- Main pattern detection function
   //--- Requires 5 swing points: X, A, B, C, D (oldest to newest)
   ENUM_HARMONIC_PATTERN CheckPatterns(const SwingPoint &swings[], HarmonicPatternResult &result)
     {
      int count = ArraySize(swings);
      if(count < 5)
         return HARMONIC_NONE;
      
      //--- Get the 5 points (X, A, B, C, D)
      //--- We expect alternating high/low points
      SwingPoint X = swings[count - 5];
      SwingPoint A = swings[count - 4];
      SwingPoint B = swings[count - 3];
      SwingPoint C = swings[count - 2];
      SwingPoint D = swings[count - 1];
      
      //--- Determine if this is a bullish or bearish setup
      //--- Bullish: D is at a low (potential buy zone)
      //--- Bearish: D is at a high (potential sell zone)
      bool isBullish = !D.isHigh;  // If D is a swing low, it's bullish
      
      //--- Validate alternating pattern
      if(!ValidateAlternatingSwings(X, A, B, C, D))
         return HARMONIC_NONE;
      
      //--- Calculate leg distances
      double XA = MathAbs(A.price - X.price);
      double AB = MathAbs(B.price - A.price);
      double BC = MathAbs(C.price - B.price);
      double CD = MathAbs(D.price - C.price);
      double AD = MathAbs(D.price - A.price);
      double XC = MathAbs(C.price - X.price);
      
      //--- Avoid division by zero
      if(XA == 0 || AB == 0 || BC == 0)
         return HARMONIC_NONE;
      
      //--- Calculate Fibonacci ratios
      double ab2xa = AB / XA;
      double bc2ab = BC / AB;
      double cd2bc = CD / BC;
      double ad2xa = AD / XA;
      double cd2xc = (XC > 0) ? CD / XC : 0;
      double xc2xa = XC / XA;
      
      //--- Check each pattern
      for(int i = 0; i < m_numPatterns; i++)
        {
         if(MatchPattern(i, ab2xa, bc2ab, cd2bc, ad2xa, cd2xc, xc2xa))
           {
            //--- Pattern found! Fill result
            result.type = IndexToPatternEnum(i);
            result.isBullish = isBullish;
            result.X = X.price;
            result.A = A.price;
            result.B = B.price;
            result.C = C.price;
            result.D = D.price;
            result.XTime = X.time;
            result.ATime = A.time;
            result.BTime = B.time;
            result.CTime = C.time;
            result.DTime = D.time;
            result.patternName = m_patternNames[i];
            
            //--- Calculate PRZ (Potential Reversal Zone)
            CalculatePRZ(result, XA, isBullish);
            
            //--- Calculate confidence based on how close ratios are to ideal
            result.confidence = CalculateConfidence(i, ab2xa, bc2ab, cd2bc, ad2xa);
            
            return result.type;
           }
        }
      
      return HARMONIC_NONE;
     }

   //--- Convert pattern enum to string
   string PatternToString(ENUM_HARMONIC_PATTERN pattern)
     {
      switch(pattern)
        {
         case HARMONIC_ABCD:        return "AB=CD";
         case HARMONIC_GARTLEY:     return "Gartley";
         case HARMONIC_BAT:         return "Bat";
         case HARMONIC_ALT_BAT:     return "Alt. Bat";
         case HARMONIC_BUTTERFLY:   return "Butterfly";
         case HARMONIC_CRAB:        return "Crab";
         case HARMONIC_DEEP_CRAB:   return "Deep Crab";
         case HARMONIC_THREE_DRIVES: return "Three Drives";
         case HARMONIC_CYPHER:      return "Cypher";
         case HARMONIC_SHARK:       return "Shark";
         case HARMONIC_FIVE_O:      return "5-0";
         case HARMONIC_NEN_STAR:    return "Nen Star";
         case HARMONIC_BLACK_SWAN:  return "Black Swan";
         case HARMONIC_WHITE_SWAN:  return "White Swan";
         default:                   return "None";
        }
     }
     
   //--- Check if pattern is bullish by nature
   bool IsBullishPattern(ENUM_HARMONIC_PATTERN pattern, bool patternIsBullish)
     {
      return patternIsBullish;  // Determined by D-point location
     }

private:
   //--- Populate pattern definitions (from HarmonicPatternFinder)
   void PopulatePatterns(void)
     {
      m_numPatterns = 14;
      ArrayResize(m_patterns, m_numPatterns);
      ArrayResize(m_patternNames, m_numPatterns);
      
      //--- AB=CD: No XA constraint, BC/AB = 0.618-0.786, CD/BC = 1.272-1.618
      m_patterns[0].ab2xa_min = 0; m_patterns[0].ab2xa_max = 0;
      m_patterns[0].bc2ab_min = 0.618; m_patterns[0].bc2ab_max = 0.786;
      m_patterns[0].cd2bc_min = 1.272; m_patterns[0].cd2bc_max = 1.618;
      m_patterns[0].ad2xa_min = 0; m_patterns[0].ad2xa_max = 0;
      m_patterns[0].cd2xc_min = 0; m_patterns[0].cd2xc_max = 0;
      m_patterns[0].xc2xa_min = 0; m_patterns[0].xc2xa_max = 0;
      m_patternNames[0] = "AB=CD";
      
      //--- Gartley: AB/XA = 0.618, BC/AB = 0.382-0.886, CD/BC = 1.272-1.618, AD/XA = 0.786
      m_patterns[1].ab2xa_min = 0.618; m_patterns[1].ab2xa_max = 0.618;
      m_patterns[1].bc2ab_min = 0.382; m_patterns[1].bc2ab_max = 0.886;
      m_patterns[1].cd2bc_min = 1.272; m_patterns[1].cd2bc_max = 1.618;
      m_patterns[1].ad2xa_min = 0.786; m_patterns[1].ad2xa_max = 0.786;
      m_patterns[1].cd2xc_min = 0; m_patterns[1].cd2xc_max = 0;
      m_patterns[1].xc2xa_min = 0; m_patterns[1].xc2xa_max = 0;
      m_patternNames[1] = "Gartley";
      
      //--- Bat: AB/XA = 0.382-0.5, BC/AB = 0.382-0.886, CD/BC = 1.618-2.618, AD/XA = 0.886
      m_patterns[2].ab2xa_min = 0.382; m_patterns[2].ab2xa_max = 0.5;
      m_patterns[2].bc2ab_min = 0.382; m_patterns[2].bc2ab_max = 0.886;
      m_patterns[2].cd2bc_min = 1.618; m_patterns[2].cd2bc_max = 2.618;
      m_patterns[2].ad2xa_min = 0.886; m_patterns[2].ad2xa_max = 0.886;
      m_patterns[2].cd2xc_min = 0; m_patterns[2].cd2xc_max = 0;
      m_patterns[2].xc2xa_min = 0; m_patterns[2].xc2xa_max = 0;
      m_patternNames[2] = "Bat";
      
      //--- Alt. Bat: AB/XA = 0.382, BC/AB = 0.382-0.886, CD/BC = 2.0-3.618, AD/XA = 1.13
      m_patterns[3].ab2xa_min = 0.382; m_patterns[3].ab2xa_max = 0.382;
      m_patterns[3].bc2ab_min = 0.382; m_patterns[3].bc2ab_max = 0.886;
      m_patterns[3].cd2bc_min = 2.0; m_patterns[3].cd2bc_max = 3.618;
      m_patterns[3].ad2xa_min = 1.13; m_patterns[3].ad2xa_max = 1.13;
      m_patterns[3].cd2xc_min = 0; m_patterns[3].cd2xc_max = 0;
      m_patterns[3].xc2xa_min = 0; m_patterns[3].xc2xa_max = 0;
      m_patternNames[3] = "Alt. Bat";
      
      //--- Butterfly: AB/XA = 0.786, BC/AB = 0.382-0.886, CD/BC = 1.618-2.618, AD/XA = 1.272-1.618
      m_patterns[4].ab2xa_min = 0.786; m_patterns[4].ab2xa_max = 0.786;
      m_patterns[4].bc2ab_min = 0.382; m_patterns[4].bc2ab_max = 0.886;
      m_patterns[4].cd2bc_min = 1.618; m_patterns[4].cd2bc_max = 2.618;
      m_patterns[4].ad2xa_min = 1.272; m_patterns[4].ad2xa_max = 1.618;
      m_patterns[4].cd2xc_min = 0; m_patterns[4].cd2xc_max = 0;
      m_patterns[4].xc2xa_min = 0; m_patterns[4].xc2xa_max = 0;
      m_patternNames[4] = "Butterfly";
      
      //--- Crab: AB/XA = 0.382-0.618, BC/AB = 0.382-0.886, CD/BC = 2.24-3.618, AD/XA = 1.618
      m_patterns[5].ab2xa_min = 0.382; m_patterns[5].ab2xa_max = 0.618;
      m_patterns[5].bc2ab_min = 0.382; m_patterns[5].bc2ab_max = 0.886;
      m_patterns[5].cd2bc_min = 2.24; m_patterns[5].cd2bc_max = 3.618;
      m_patterns[5].ad2xa_min = 1.618; m_patterns[5].ad2xa_max = 1.618;
      m_patterns[5].cd2xc_min = 0; m_patterns[5].cd2xc_max = 0;
      m_patterns[5].xc2xa_min = 0; m_patterns[5].xc2xa_max = 0;
      m_patternNames[5] = "Crab";
      
      //--- Deep Crab: AB/XA = 0.886, BC/AB = 0.382-0.886, CD/BC = 2.618-3.618, AD/XA = 1.618
      m_patterns[6].ab2xa_min = 0.886; m_patterns[6].ab2xa_max = 0.886;
      m_patterns[6].bc2ab_min = 0.382; m_patterns[6].bc2ab_max = 0.886;
      m_patterns[6].cd2bc_min = 2.618; m_patterns[6].cd2bc_max = 3.618;
      m_patterns[6].ad2xa_min = 1.618; m_patterns[6].ad2xa_max = 1.618;
      m_patterns[6].cd2xc_min = 0; m_patterns[6].cd2xc_max = 0;
      m_patterns[6].xc2xa_min = 0; m_patterns[6].xc2xa_max = 0;
      m_patternNames[6] = "Deep Crab";
      
      //--- Three Drives: AB/XA = 1.272-1.618, BC/AB = 0.618-0.786, CD/BC = 1.272-1.618
      m_patterns[7].ab2xa_min = 1.272; m_patterns[7].ab2xa_max = 1.618;
      m_patterns[7].bc2ab_min = 0.618; m_patterns[7].bc2ab_max = 0.786;
      m_patterns[7].cd2bc_min = 1.272; m_patterns[7].cd2bc_max = 1.618;
      m_patterns[7].ad2xa_min = 0; m_patterns[7].ad2xa_max = 0;
      m_patterns[7].cd2xc_min = 0; m_patterns[7].cd2xc_max = 0;
      m_patterns[7].xc2xa_min = 0; m_patterns[7].xc2xa_max = 0;
      m_patternNames[7] = "Three Drives";
      
      //--- Cypher: AB/XA = 0.382-0.618, XC/XA = 1.13-1.414, CD/XC = 0.786
      m_patterns[8].ab2xa_min = 0.382; m_patterns[8].ab2xa_max = 0.618;
      m_patterns[8].bc2ab_min = 0; m_patterns[8].bc2ab_max = 0;
      m_patterns[8].cd2bc_min = 0; m_patterns[8].cd2bc_max = 0;
      m_patterns[8].ad2xa_min = 0; m_patterns[8].ad2xa_max = 0;
      m_patterns[8].cd2xc_min = 0.786; m_patterns[8].cd2xc_max = 0.786;
      m_patterns[8].xc2xa_min = 1.13; m_patterns[8].xc2xa_max = 1.414;
      m_patternNames[8] = "Cypher";
      
      //--- Shark: BC/AB = 1.13-1.618, CD/BC = 1.618-2.24, CD/XC = 0.886-1.13
      m_patterns[9].ab2xa_min = 0; m_patterns[9].ab2xa_max = 0;
      m_patterns[9].bc2ab_min = 1.13; m_patterns[9].bc2ab_max = 1.618;
      m_patterns[9].cd2bc_min = 1.618; m_patterns[9].cd2bc_max = 2.24;
      m_patterns[9].ad2xa_min = 0; m_patterns[9].ad2xa_max = 0;
      m_patterns[9].cd2xc_min = 0.886; m_patterns[9].cd2xc_max = 1.13;
      m_patterns[9].xc2xa_min = 0; m_patterns[9].xc2xa_max = 0;
      m_patternNames[9] = "Shark";
      
      //--- 5-0: AB/XA = 1.13-1.618, BC/AB = 1.618-2.24, CD/BC = 0.5
      m_patterns[10].ab2xa_min = 1.13; m_patterns[10].ab2xa_max = 1.618;
      m_patterns[10].bc2ab_min = 1.618; m_patterns[10].bc2ab_max = 2.24;
      m_patterns[10].cd2bc_min = 0.5; m_patterns[10].cd2bc_max = 0.5;
      m_patterns[10].ad2xa_min = 0; m_patterns[10].ad2xa_max = 0;
      m_patterns[10].cd2xc_min = 0; m_patterns[10].cd2xc_max = 0;
      m_patterns[10].xc2xa_min = 0; m_patterns[10].xc2xa_max = 0;
      m_patternNames[10] = "5-0";
      
      //--- Nen Star: AB/XA = 0.382-0.618, XC/XA = 1.13-1.414, CD/XC = 1.272
      m_patterns[11].ab2xa_min = 0.382; m_patterns[11].ab2xa_max = 0.618;
      m_patterns[11].bc2ab_min = 0; m_patterns[11].bc2ab_max = 0;
      m_patterns[11].cd2bc_min = 0; m_patterns[11].cd2bc_max = 0;
      m_patterns[11].ad2xa_min = 0; m_patterns[11].ad2xa_max = 0;
      m_patterns[11].cd2xc_min = 1.272; m_patterns[11].cd2xc_max = 1.272;
      m_patterns[11].xc2xa_min = 1.13; m_patterns[11].xc2xa_max = 1.414;
      m_patternNames[11] = "Nen Star";
      
      //--- Black Swan: AB/XA = 1.382-2.618, BC/AB = 0.236-0.5, CD/BC = 1.128-2.0, AD/XA = 1.128-2.618
      m_patterns[12].ab2xa_min = 1.382; m_patterns[12].ab2xa_max = 2.618;
      m_patterns[12].bc2ab_min = 0.236; m_patterns[12].bc2ab_max = 0.5;
      m_patterns[12].cd2bc_min = 1.128; m_patterns[12].cd2bc_max = 2.0;
      m_patterns[12].ad2xa_min = 1.128; m_patterns[12].ad2xa_max = 2.618;
      m_patterns[12].cd2xc_min = 0; m_patterns[12].cd2xc_max = 0;
      m_patterns[12].xc2xa_min = 0; m_patterns[12].xc2xa_max = 0;
      m_patternNames[12] = "Black Swan";
      
      //--- White Swan: AB/XA = 0.382-0.724, BC/AB = 2.0-4.237, CD/BC = 0.5-0.886, AD/XA = 0.382-0.886
      m_patterns[13].ab2xa_min = 0.382; m_patterns[13].ab2xa_max = 0.724;
      m_patterns[13].bc2ab_min = 2.0; m_patterns[13].bc2ab_max = 4.237;
      m_patterns[13].cd2bc_min = 0.5; m_patterns[13].cd2bc_max = 0.886;
      m_patterns[13].ad2xa_min = 0.382; m_patterns[13].ad2xa_max = 0.886;
      m_patterns[13].cd2xc_min = 0; m_patterns[13].cd2xc_max = 0;
      m_patterns[13].xc2xa_min = 0; m_patterns[13].xc2xa_max = 0;
      m_patternNames[13] = "White Swan";
     }

   //--- Check if swing points alternate properly (high-low-high-low or low-high-low-high)
   bool ValidateAlternatingSwings(const SwingPoint &X, const SwingPoint &A, 
                                   const SwingPoint &B, const SwingPoint &C, 
                                   const SwingPoint &D)
     {
      //--- X and A should be different (high vs low)
      if(X.isHigh == A.isHigh) return false;
      //--- A and B should be different
      if(A.isHigh == B.isHigh) return false;
      //--- B and C should be different
      if(B.isHigh == C.isHigh) return false;
      //--- C and D should be different
      if(C.isHigh == D.isHigh) return false;
      
      return true;
     }

   //--- Check if a pattern index matches the current ratios
   bool MatchPattern(int idx, double ab2xa, double bc2ab, double cd2bc, 
                     double ad2xa, double cd2xc, double xc2xa)
     {
      HarmonicRatios p = m_patterns[idx];
      
      //--- Check AB/XA ratio (if constraint exists)
      if(p.ab2xa_max > 0 || p.ab2xa_min > 0)
        {
         double slack = (p.ab2xa_max == p.ab2xa_min) ? m_slackUnary : m_slackRange;
         if(!IsWithinRange(ab2xa, p.ab2xa_min, p.ab2xa_max, slack))
            return false;
        }
      
      //--- Check BC/AB ratio
      if(p.bc2ab_max > 0 || p.bc2ab_min > 0)
        {
         double slack = (p.bc2ab_max == p.bc2ab_min) ? m_slackUnary : m_slackRange;
         if(!IsWithinRange(bc2ab, p.bc2ab_min, p.bc2ab_max, slack))
            return false;
        }
      
      //--- Check CD/BC ratio
      if(p.cd2bc_max > 0 || p.cd2bc_min > 0)
        {
         double slack = (p.cd2bc_max == p.cd2bc_min) ? m_slackUnary : m_slackRange;
         if(!IsWithinRange(cd2bc, p.cd2bc_min, p.cd2bc_max, slack))
            return false;
        }
      
      //--- Check AD/XA ratio
      if(p.ad2xa_max > 0 || p.ad2xa_min > 0)
        {
         double slack = (p.ad2xa_max == p.ad2xa_min) ? m_slackUnary : m_slackRange;
         if(!IsWithinRange(ad2xa, p.ad2xa_min, p.ad2xa_max, slack))
            return false;
        }
      
      //--- Check CD/XC ratio (for Cypher, Shark, Nen Star)
      if(p.cd2xc_max > 0 || p.cd2xc_min > 0)
        {
         double slack = (p.cd2xc_max == p.cd2xc_min) ? m_slackUnary : m_slackRange;
         if(!IsWithinRange(cd2xc, p.cd2xc_min, p.cd2xc_max, slack))
            return false;
        }
      
      //--- Check XC/XA ratio (for Cypher, Nen Star)
      if(p.xc2xa_max > 0 || p.xc2xa_min > 0)
        {
         double slack = (p.xc2xa_max == p.xc2xa_min) ? m_slackUnary : m_slackRange;
         if(!IsWithinRange(xc2xa, p.xc2xa_min, p.xc2xa_max, slack))
            return false;
        }
      
      return true;
     }

   //--- Check if value is within range with slack tolerance
   bool IsWithinRange(double value, double min_val, double max_val, double slack)
     {
      return (value >= min_val - slack && value <= max_val + slack);
     }

   //--- Convert pattern index to enum
   ENUM_HARMONIC_PATTERN IndexToPatternEnum(int idx)
     {
      switch(idx)
        {
         case 0:  return HARMONIC_ABCD;
         case 1:  return HARMONIC_GARTLEY;
         case 2:  return HARMONIC_BAT;
         case 3:  return HARMONIC_ALT_BAT;
         case 4:  return HARMONIC_BUTTERFLY;
         case 5:  return HARMONIC_CRAB;
         case 6:  return HARMONIC_DEEP_CRAB;
         case 7:  return HARMONIC_THREE_DRIVES;
         case 8:  return HARMONIC_CYPHER;
         case 9:  return HARMONIC_SHARK;
         case 10: return HARMONIC_FIVE_O;
         case 11: return HARMONIC_NEN_STAR;
         case 12: return HARMONIC_BLACK_SWAN;
         case 13: return HARMONIC_WHITE_SWAN;
         default: return HARMONIC_NONE;
        }
     }

   //--- Calculate Potential Reversal Zone
   void CalculatePRZ(HarmonicPatternResult &result, double XA, bool isBullish)
     {
      //--- PRZ is typically around the D-point
      //--- Add a tolerance zone based on XA leg size
      double tolerance = XA * 0.05;  // 5% of XA
      
      if(isBullish)
        {
         result.prz_low = result.D - tolerance;
         result.prz_high = result.D + tolerance;
        }
      else
        {
         result.prz_low = result.D - tolerance;
         result.prz_high = result.D + tolerance;
        }
     }

   //--- Calculate confidence score based on ratio accuracy
   double CalculateConfidence(int idx, double ab2xa, double bc2ab, double cd2bc, double ad2xa)
     {
      HarmonicRatios p = m_patterns[idx];
      double totalDeviation = 0;
      int ratioCount = 0;
      
      //--- Check deviation from ideal for each ratio
      if(p.ab2xa_max > 0)
        {
         double ideal = (p.ab2xa_min + p.ab2xa_max) / 2;
         totalDeviation += MathAbs(ab2xa - ideal) / ideal;
         ratioCount++;
        }
      
      if(p.bc2ab_max > 0)
        {
         double ideal = (p.bc2ab_min + p.bc2ab_max) / 2;
         totalDeviation += MathAbs(bc2ab - ideal) / ideal;
         ratioCount++;
        }
      
      if(p.cd2bc_max > 0)
        {
         double ideal = (p.cd2bc_min + p.cd2bc_max) / 2;
         totalDeviation += MathAbs(cd2bc - ideal) / ideal;
         ratioCount++;
        }
      
      if(p.ad2xa_max > 0)
        {
         double ideal = (p.ad2xa_min + p.ad2xa_max) / 2;
         totalDeviation += MathAbs(ad2xa - ideal) / ideal;
         ratioCount++;
        }
      
      if(ratioCount == 0)
         return 0.5;
      
      double avgDeviation = totalDeviation / ratioCount;
      
      //--- Convert deviation to confidence (lower deviation = higher confidence)
      double confidence = 1.0 - MathMin(avgDeviation, 1.0);
      
      return confidence;
     }
  };

#endif // LULA_HARMONIC_RECOGNIZER_MQH
//+------------------------------------------------------------------+
