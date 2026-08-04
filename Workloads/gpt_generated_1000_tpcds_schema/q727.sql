WITH
  inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
  ),
  base AS (
    SELECT
      s.s_state,
      i.i_category,
      ss.ss_net_paid,
      ss.ss_net_profit,
      p.p_promo_name,
      cc.cc_name,
      sm.sm_type,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      wp.wp_url,
      pw.word        AS promo_word,
      inv_agg.total_on_hand,
      (
        SELECT MAX(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
      )               AS max_ext_price
    FROM store_sales ss
    JOIN store s                     ON ss.ss_store_sk = s.s_store_sk
    JOIN item i                      ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d                  ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t                  ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p                 ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN LATERAL (
      SELECT word
      FROM UNNEST(SPLIT(p.p_channel_details, ' ')) AS t(word)
    ) pw ON true
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr         ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_sales cs         ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p_cs           ON cs.cs_promo_sk = p_cs.p_promo_sk
    LEFT JOIN web_returns wr          ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN web_page wp              ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN (
      SELECT *
      FROM web_page
      TABLESAMPLE BERNOULLI (5)
    ) wp_sample ON wp.wp_web_page_sk = wp_sample.wp_web_page_sk
    LEFT JOIN inv_agg                  ON i.i_item_sk = inv_agg.inv_item_sk
    WHERE EXISTS (
      SELECT 1
      FROM store_returns sr2
      WHERE sr2.sr_item_sk = i.i_item_sk
        AND sr2.sr_return_quantity > 0
    )
  ),
  agg AS (
    SELECT
      s_state,
      i_category,
      SUM(ss_net_paid)   AS total_net_paid,
      SUM(ss_net_profit) AS total_profit
    FROM base
    GROUP BY ROLLUP (s_state, i_category)
  ),
  exclude AS (
    SELECT
      s.s_state   AS s_state,
      i.i_category AS i_category,
      0.0          AS total_net_paid,
      0.0          AS total_profit
    FROM store s
    CROSS JOIN item i
    WHERE s.s_state = 'CA'
  )
SELECT
  agg.s_state,
  agg.i_category,
  agg.total_net_paid,
  agg.total_profit
FROM agg
EXCEPT
SELECT
  exc.s_state,
  exc.i_category,
  exc.total_net_paid,
  exc.total_profit
FROM exclude exc
ORDER BY total_net_paid DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
