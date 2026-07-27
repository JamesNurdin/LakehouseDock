WITH joined AS (
    SELECT
        d.d_year,
        d.d_date,
        cp.cp_department,
        cs.cs_net_profit,
        cs.cs_quantity,
        ws.ws_ext_tax,
        sr.sr_return_quantity,
        t.t_hour,
        cd.cd_gender,
        cd.cd_dep_count
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON t.t_time_sk = sr.sr_return_time_sk
    JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = sr.sr_cdemo_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
      AND cp.cp_department = 'Books'
      AND ws.ws_ext_tax > 20.00
      AND sr.sr_return_quantity > 1
),
agg AS (
    SELECT
        d_year,
        cp_department,
        SUM(cs_net_profit) AS total_net_profit,
        AVG(cs_quantity) AS avg_quantity,
        COUNT(DISTINCT ws_ext_tax) AS distinct_tax_count
    FROM joined
    GROUP BY d_year, cp_department
)
SELECT
    d_year,
    cp_department,
    total_net_profit,
    avg_quantity,
    distinct_tax_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 100
