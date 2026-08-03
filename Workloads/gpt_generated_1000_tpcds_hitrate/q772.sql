WITH base AS (
    SELECT
        r.r_reason_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        CASE 
            WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH'
            WHEN SUM(cr.cr_net_loss) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND r.r_reason_id IN ('R001', 'R002')
      AND w.w_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND cd.cd_gender = 'M'
    GROUP BY r.r_reason_desc, ib.ib_lower_bound, ib.ib_upper_bound
),
store AS (
    SELECT
        r.r_reason_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt_inc_tax) AS total_sales,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_orders,
        CASE 
            WHEN SUM(sr.sr_net_loss) > 8000 THEN 'HIGH'
            WHEN SUM(sr.sr_net_loss) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND r.r_reason_id IN ('R001', 'R002')
      AND ib.ib_upper_bound <= 150000
      AND cd.cd_marital_status = 'S'
      AND EXISTS (
          SELECT 1 FROM warehouse w
          WHERE w.w_state = 'CA' AND w.w_warehouse_sq_ft > 100000
      )
    GROUP BY r.r_reason_desc, ib.ib_lower_bound, ib.ib_upper_bound
),
union_all AS (
    SELECT * FROM base
    UNION DISTINCT
    SELECT * FROM store
)
SELECT
    ua.r_reason_desc,
    ua.ib_lower_bound,
    ua.ib_upper_bound,
    ua.loss_category,
    ua.total_net_loss,
    ua.total_sales,
    ua.distinct_orders,
    (
        SELECT COALESCE(SUM(wr.wr_return_amt_inc_tax), 0)
        FROM web_returns wr
        JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
        JOIN household_demographics hd2 ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
        JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
        WHERE r2.r_reason_desc = ua.r_reason_desc
          AND ib2.ib_lower_bound = ua.ib_lower_bound
          AND ib2.ib_upper_bound = ua.ib_upper_bound
    ) AS web_return_sales,
    CASE WHEN ua.total_sales > (
            SELECT AVG(cs.cs_ext_sales_price)
            FROM catalog_sales cs
            WHERE cs.cs_sold_date_sk IS NOT NULL
        ) THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS sales_compared_to_avg
FROM union_all ua
WHERE ua.total_net_loss > 0
ORDER BY ua.total_net_loss DESC
LIMIT 100
