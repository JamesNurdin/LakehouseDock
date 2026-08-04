WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cr.cr_net_loss,
        sr.sr_net_loss,
        c.c_customer_id,
        c.c_customer_sk,
        d.d_year,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        cd.cd_gender,
        r.r_reason_id,
        t.t_hour,
        w.web_site_id
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d
        ON d.d_date_sk = cs.cs_sold_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON t.t_time_sk = cs.cs_sold_time_sk
    JOIN customer c
        ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN customer_demographics cd
        ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN reason r
        ON r.r_reason_sk = cr.cr_reason_sk
    JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND hd.hd_dep_count >= 2
      AND cd.cd_gender = 'M'
      AND r.r_reason_id = 'AAAAAAAADAAAAAAA'
      AND cs.cs_ext_ship_cost > 500
      AND t.t_hour BETWEEN 8 AND 18
)
SELECT
    c_customer_id,
    d_year,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    (SUM(cr_net_loss) + SUM(sr_net_loss)) AS total_loss,
    CASE
        WHEN SUM(cs_net_profit) - (SUM(cr_net_loss) + SUM(sr_net_loss)) > 1000 THEN 'High'
        WHEN SUM(cs_net_profit) - (SUM(cr_net_loss) + SUM(sr_net_loss)) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (
        PARTITION BY d_year
        ORDER BY (SUM(cs_net_profit) - (SUM(cr_net_loss) + SUM(sr_net_loss))) DESC
    ) AS profit_rank
FROM joined
GROUP BY c_customer_id, d_year
ORDER BY profit_rank
LIMIT 100
