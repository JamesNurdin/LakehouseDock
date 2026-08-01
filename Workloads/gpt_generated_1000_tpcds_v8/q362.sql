WITH diff_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
),

base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        wr.wr_return_amt,
        r.r_reason_desc,
        c.c_customer_id,
        c.c_last_name,
        web_site.web_name,
        CASE
            WHEN cs.cs_net_profit > 0 THEN 'PROFIT'
            ELSE 'LOSS'
        END AS profit_category
    FROM catalog_sales cs
    FULL OUTER JOIN web_sales ws
        ON cs.cs_bill_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer c
        ON (cs.cs_bill_customer_sk = c.c_customer_sk OR ws.ws_bill_customer_sk = c.c_customer_sk)
    LEFT JOIN web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
      AND ws.ws_sold_date_sk IS NOT NULL
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND web_site.web_country = 'United States'
      AND r.r_reason_desc IS NOT NULL
      AND cs.cs_order_number IN (SELECT cs_order_number FROM diff_orders)
),

agg AS (
    SELECT
        c_customer_id,
        web_name,
        profit_category,
        SUM(cs_ext_sales_price) AS sum_catalog_sales,
        SUM(ws_ext_sales_price) AS sum_web_sales,
        SUM(wr_return_amt) AS sum_returns,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY CUBE (c_customer_id, web_name, profit_category)
)

SELECT
    c_customer_id,
    web_name,
    profit_category,
    sum_catalog_sales,
    sum_web_sales,
    sum_returns,
    txn_count
FROM agg
WHERE sum_catalog_sales > (
    SELECT AVG(cs_ext_sales_price)
    FROM catalog_sales
    WHERE cs_sold_date_sk = 2452634
)
ORDER BY sum_catalog_sales DESC
LIMIT 100
