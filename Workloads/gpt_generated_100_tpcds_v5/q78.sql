WITH sales_agg AS (
    SELECT
        ws.web_name,
        cd.cd_gender,
        td.t_shift,
        dd.d_month_seq,
        SUM(cs.cs_net_paid) AS total_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim dd
        ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = dd.d_date_sk
    WHERE dd.d_weekend = 'Y'
      AND dd.d_month_seq IN (5, 6, 11)
      AND cs.cs_net_profit > 0
      AND td.t_shift = 'second'
      AND cd.cd_gender = 'M'
      AND ws.web_tax_percentage > 0.05
    GROUP BY ws.web_name, cd.cd_gender, td.t_shift, dd.d_month_seq
)
SELECT
    web_name,
    cd_gender,
    t_shift,
    d_month_seq,
    total_paid,
    total_profit,
    order_cnt,
    total_profit / NULLIF(total_paid, 0) AS profit_ratio
FROM sales_agg
WHERE total_profit / NULLIF(total_paid, 0) > 100
ORDER BY profit_ratio DESC
LIMIT 100
