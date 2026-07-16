WITH sales_agg AS (
    -- Catalog channel aggregation
    SELECT
        p.p_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        cs.cs_sold_date_sk AS sale_date_sk,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity,
        SUM(cs.cs_ext_discount_amt) AS discount,
        0 AS return_cnt,
        COUNT(*) AS sales_cnt,
        'Catalog' AS channel
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month = 5
      AND c.c_birth_year BETWEEN 1960 AND 1970
      AND p.p_start_date_sk <= cs.cs_sold_date_sk
      AND p.p_end_date_sk >= cs.cs_sold_date_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, cs.cs_sold_date_sk

    UNION ALL

    -- Store channel aggregation (including returns)
    SELECT
        p.p_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        ss.ss_sold_date_sk AS sale_date_sk,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS quantity,
        SUM(ss.ss_ext_discount_amt) AS discount,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_cnt,
        COUNT(*) AS sales_cnt,
        'Store' AS channel
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_customer_sk = sr.sr_customer_sk
    WHERE c.c_birth_month = 5
      AND c.c_birth_year BETWEEN 1960 AND 1970
      AND p.p_start_date_sk <= ss.ss_sold_date_sk
      AND p.p_end_date_sk >= ss.ss_sold_date_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, ss.ss_sold_date_sk

    UNION ALL

    -- Web channel aggregation
    SELECT
        p.p_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        ws.ws_sold_date_sk AS sale_date_sk,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS quantity,
        SUM(ws.ws_ext_discount_amt) AS discount,
        0 AS return_cnt,
        COUNT(*) AS sales_cnt,
        'Web' AS channel
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month = 5
      AND c.c_birth_year BETWEEN 1960 AND 1970
      AND p.p_start_date_sk <= ws.ws_sold_date_sk
      AND p.p_end_date_sk >= ws.ws_sold_date_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, ws.ws_sold_date_sk
),

promo_monthly AS (
    SELECT
        promo_sk,
        promo_name,
        sale_date_sk,
        SUM(net_profit) AS total_net_profit,
        SUM(quantity) AS total_quantity,
        SUM(discount) AS total_discount,
        SUM(return_cnt) AS total_returns,
        SUM(sales_cnt) AS total_sales
    FROM sales_agg
    GROUP BY promo_sk, promo_name, sale_date_sk
)

SELECT
    promo_sk,
    promo_name,
    date_add('day', sale_date_sk, date '1970-01-01') AS sale_date,
    total_net_profit,
    total_quantity,
    total_discount,
    total_returns,
    total_sales,
    CASE WHEN total_sales > 0 THEN total_returns * 1.0 / total_sales ELSE 0 END AS return_rate,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM promo_monthly
WHERE total_net_profit > 0
ORDER BY total_net_profit DESC
LIMIT 10
