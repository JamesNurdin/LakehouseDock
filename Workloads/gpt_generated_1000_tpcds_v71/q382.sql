WITH joined AS (
    SELECT DISTINCT
        d.d_year,
        d.d_date,
        cc.cc_state,
        sm.sm_carrier,
        ib.ib_income_band_sk,
        p.p_promo_id,
        cs.cs_ext_sales_price,
        ss.ss_ext_sales_price,
        sr.sr_return_amt,
        cs.cs_net_profit,
        ss.ss_net_profit,
        sr.sr_net_loss
    FROM catalog_sales cs
    JOIN date_dim d                ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm              ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN promotion p               ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN customer_address ca       ON cs.cs_bill_addr_sk   = ca.ca_address_sk
    JOIN household_demographics hb ON cs.cs_bill_hdemo_sk  = hb.hd_demo_sk
    JOIN income_band ib            ON hb.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss            ON ss.ss_sold_date_sk   = d.d_date_sk
    JOIN store s                   ON ss.ss_store_sk       = s.s_store_sk
    JOIN store_returns sr          ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_store_sk      = s.s_store_sk
    JOIN reason r                  ON sr.sr_reason_sk      = r.r_reason_sk
    JOIN date_dim d_ret            ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND s.s_state = 'CA'
      AND cc.cc_state = 'CA'
      AND sm.sm_carrier IN ('DHL', 'MSC')
      AND p.p_discount_active = 'Y'
      AND ib.ib_lower_bound >= 50000
      AND r.r_reason_desc LIKE '%defect%'
),
agg AS (
    SELECT
        d_year,
        cc_state,
        sm_carrier,
        ib_income_band_sk,
        SUM(cs_ext_sales_price) AS sum_catalog_sales,
        SUM(ss_ext_sales_price) AS sum_store_sales,
        SUM(sr_return_amt)      AS sum_returns,
        SUM(cs_net_profit) + SUM(ss_net_profit) - SUM(sr_net_loss) AS net_profit
    FROM joined
    GROUP BY GROUPING SETS (
        (d_year, cc_state, sm_carrier, ib_income_band_sk),
        (d_year, cc_state, sm_carrier),
        (d_year, cc_state),
        (d_year)
    )
)
SELECT
    d_year,
    cc_state,
    sm_carrier,
    ib_income_band_sk,
    sum_catalog_sales,
    sum_store_sales,
    sum_returns,
    net_profit,
    RANK() OVER (ORDER BY net_profit DESC) AS profit_rank
FROM agg
WHERE sum_catalog_sales > 100000
  AND sum_store_sales   > 50000
  AND ib_income_band_sk IS NOT NULL
  AND cc_state          IS NOT NULL
  AND sm_carrier        IS NOT NULL
  AND d_year            IS NOT NULL
ORDER BY net_profit DESC, d_year
LIMIT 100
