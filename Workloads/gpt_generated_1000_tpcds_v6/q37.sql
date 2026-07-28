/* goal: Identify top household demographics by total return amount, enriched with profit metrics from catalog, store and web sales, and rank them within income bands. The query joins all seven selected tables, applies multiple filters, uses a scalar subquery, an EXISTS filter, DISTINCT in the subquery, window ranking functions, and limits the result to the top 100 rows. */
WITH joined_data AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_item_sk,
        cs.cs_item_sk AS cs_item_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_paid_inc_ship_tax AS cs_net_paid,
        ss.ss_net_profit,
        ws.ws_net_profit,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_ship_mode_sk
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_item_sk IN (86978, 129416, 197860)
      AND cr.cr_return_quantity > 0
      AND sm.sm_type = 'AIR'
      AND ib.ib_lower_bound >= 50000
      AND cs.cs_net_paid_inc_ship_tax > 2000
      AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_bill_hdemo_sk = hd.hd_demo_sk
              AND ws2.ws_quantity > 10
        )
)
SELECT
    hd_demo_sk,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    sm_ship_mode_id,
    sm_type,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cs_net_paid) AS total_sales_inc_tax,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(ws_net_profit) AS total_web_profit,
    (
        SELECT AVG(DISTINCT cs3.cs_list_price)
        FROM catalog_sales cs3
        WHERE cs3.cs_item_sk = jd.cr_item_sk
    ) AS avg_list_price_for_item,
    RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY SUM(cr_return_amount) DESC) AS return_rank_by_income_band,
    ROW_NUMBER() OVER (ORDER BY SUM(cr_return_amount) DESC) AS overall_row_num
FROM joined_data jd
GROUP BY
    hd_demo_sk,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    sm_ship_mode_id,
    sm_type,
    jd.cr_item_sk,
    hd_income_band_sk
ORDER BY total_return_amount DESC
LIMIT 100
