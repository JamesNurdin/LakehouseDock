WITH common_items AS (
    SELECT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    INTERSECT
    SELECT ws.ws_item_sk
    FROM web_sales ws
),
fact_agg AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_category AS category,
        i.i_brand AS brand,
        hd.hd_income_band_sk AS income_band,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Positive' ELSE 'NegativeOrZero' END AS profit_flag
    FROM store_sales ss
    JOIN common_items ci ON ss.ss_item_sk = ci.item_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
                                 AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                             AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE s.s_state = 'CA'
      AND i.i_current_price > 50.00
      AND hd.hd_income_band_sk IN (1, 2, 3)
      AND ss.ss_sold_date_sk > (
          SELECT max(cs_sold_date_sk) FROM catalog_sales
      )
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr WHERE wr.wr_item_sk = i.i_item_sk
      )
    GROUP BY ROLLUP (
        s.s_store_id,
        i.i_category,
        i.i_brand,
        hd.hd_income_band_sk
    )
    HAVING SUM(ss.ss_net_profit) > 1000
       AND COUNT(DISTINCT ss.ss_ticket_number) > 10
),
final AS (
    SELECT *,
           SUM(store_sales_amount) OVER (PARTITION BY store_id) AS total_sales_by_store,
           ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY store_net_profit DESC) AS rn_profit_rank
    FROM fact_agg
)
SELECT
    store_id,
    category,
    brand,
    income_band,
    store_net_profit,
    store_sales_amount,
    num_transactions,
    profit_flag,
    total_sales_by_store,
    rn_profit_rank
FROM final
WHERE rn_profit_rank <= 5
ORDER BY store_net_profit DESC
LIMIT 100
