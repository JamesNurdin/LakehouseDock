WITH joined AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        rs.r_reason_desc,
        inv.inv_quantity_on_hand,
        ws.web_name,
        ws.web_gmt_offset,
        ts.t_hour,
        ss.ss_quantity,
        sr.sr_return_amt,
        (
            SELECT avg(cs_sub.cs_net_paid)
            FROM catalog_sales cs_sub
            WHERE cs_sub.cs_sold_date_sk = d.d_date_sk
        ) AS avg_daily_sales
    FROM date_dim d
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
           AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason rs
        ON rs.r_reason_sk = cr.cr_reason_sk
    LEFT JOIN (
        SELECT * FROM inventory TABLESAMPLE BERNOULLI (5)
    ) inv
        ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN time_dim ts
        ON cs.cs_sold_time_sk = ts.t_time_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
           AND ss.ss_item_sk = cs.cs_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
           AND sr.sr_item_sk = ss.ss_item_sk
           AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason rs2
        ON rs2.r_reason_sk = sr.sr_reason_sk
)
SELECT
    d_date_sk,
    d_date,
    d_year,
    cs_item_sk,
    cs_order_number,
    cs_net_paid,
    cr_return_amount,
    cr_return_ship_cost,
    r_reason_desc,
    inv_quantity_on_hand,
    web_name,
    web_gmt_offset,
    t_hour,
    ss_quantity,
    sr_return_amt,
    avg_daily_sales,
    max_item_net_paid,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY cr_return_amount DESC) AS rn_year_return
FROM joined
CROSS JOIN LATERAL (
    SELECT max(cs2.cs_net_paid) AS max_item_net_paid
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = joined.cs_item_sk
) AS lat
WHERE d_year = 2001
  AND d_month_seq BETWEEN 1200 AND 1300
  AND cs_net_paid > 1000
  AND cr_return_amount BETWEEN 10 AND 500
  AND inv_quantity_on_hand > 0
  AND web_gmt_offset BETWEEN -5 AND 5
  AND t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1
        FROM store_returns sr_check
        WHERE sr_check.sr_item_sk = joined.cs_item_sk
          AND sr_check.sr_return_amt > 0
    )
LIMIT 100
