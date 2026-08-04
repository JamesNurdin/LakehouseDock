/* Goal: Calculate total and average net paid sales per item across catalog and store channels, applying multiple business filters, combine the two channel results, keep only items that appear in both channels, and return the top 100 items by combined net paid amount. */
WITH catalog_agg AS (
    SELECT
        i.i_item_id,
        p.p_promo_name        AS promo_name,
        SUM(cs.cs_net_paid)   AS total_net_paid,
        COUNT(*)              AS sales_cnt,
        SUM(cs.cs_quantity)   AS total_qty,
        AVG(cs.cs_net_paid)   AS avg_net_paid,
        MIN(cs.cs_sold_date_sk) AS min_date_sk,
        MAX(cs.cs_sold_date_sk) AS max_date_sk
    FROM catalog_sales cs
    JOIN item i               ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p          ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w          ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td          ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c           ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca  ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r           ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN income_band ib     ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_division = 1                     -- filter 1
      AND i.i_brand = 'BrandX'                    -- filter 2
      AND td.t_hour BETWEEN 9 AND 17              -- filter 3
      AND (r.r_reason_desc IS NULL OR r.r_reason_desc LIKE '%damage%') -- filter 4
      AND ib.ib_upper_bound > 50000               -- filter 5
    GROUP BY i.i_item_id, p.p_promo_name
),
store_agg AS (
    SELECT
        i.i_item_id,
        s.s_store_name        AS store_name,
        SUM(ss.ss_net_paid)   AS total_net_paid,
        COUNT(*)              AS sales_cnt,
        SUM(ss.ss_quantity)   AS total_qty,
        AVG(ss.ss_net_paid)   AS avg_net_paid,
        MIN(ss.ss_sold_date_sk) AS min_date_sk,
        MAX(ss.ss_sold_date_sk) AS max_date_sk
    FROM store_sales ss
    JOIN item i               ON ss.ss_item_sk = i.i_item_sk
    JOIN store s              ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p          ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td          ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c           ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca  ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r           ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN income_band ib     ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE s.s_number_employees > 200            -- filter 6
      AND i.i_color = 'Red'                     -- filter 7
      AND td.t_hour BETWEEN 10 AND 18           -- filter 8
      AND (r.r_reason_desc IS NULL OR r.r_reason_desc NOT LIKE '%color%') -- filter 9
      AND ib.ib_lower_bound < 30000             -- filter 10
    GROUP BY i.i_item_id, s.s_store_name
),
combined AS (
    SELECT ca.i_item_id,
           ca.promo_name        AS detail,
           ca.total_net_paid,
           ca.sales_cnt,
           ca.avg_net_paid
    FROM catalog_agg ca
    UNION DISTINCT
    SELECT sa.i_item_id,
           sa.store_name        AS detail,
           sa.total_net_paid,
           sa.sales_cnt,
           sa.avg_net_paid
    FROM store_agg sa
),
filtered AS (
    SELECT *
    FROM combined
    WHERE total_net_paid > (
            SELECT AVG(total_net_paid) FROM combined
          )                     -- scalar sub‑query
      AND sales_cnt >= 10
      AND avg_net_paid > 0
)
SELECT *
FROM filtered
WHERE i_item_id IN (
        SELECT i_item_id FROM catalog_agg
        INTERSECT
        SELECT i_item_id FROM store_agg
      )
ORDER BY total_net_paid DESC
LIMIT 100
