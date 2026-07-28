WITH sales_by_store AS (
    SELECT
        s.s_store_id,
        s.s_state,
        d.d_date,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_sales_price) AS avg_price,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_volume_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND t.t_shift = 'first'
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_store_sk = s.s_store_sk
            AND sr.sr_return_quantity > 0
      )
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = ss.ss_item_sk
            AND cr.cr_returned_date_sk = d.d_date_sk
            AND cr.cr_return_quantity > 0
      )
    GROUP BY s.s_store_id, s.s_state, d.d_date, i.i_category
    HAVING SUM(ss.ss_ext_sales_price) > 50000
)
SELECT
    sbs.s_store_id,
    sbs.s_state,
    sbs.d_date,
    sbs.i_category,
    sbs.total_sales,
    sbs.total_profit,
    sbs.sales_cnt,
    sbs.avg_price,
    sbs.sales_volume_category,
    RANK() OVER (PARTITION BY sbs.d_date ORDER BY sbs.total_sales DESC) AS sales_rank
FROM sales_by_store sbs
ORDER BY sbs.total_sales DESC, sales_rank
LIMIT 100
