WITH unified_sales AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid,
        cs.cs_ext_sales_price AS ext_sales_price,
        'catalog' AS channel,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk

    UNION ALL

    SELECT
        ss.ss_ticket_number AS order_number,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        ss.ss_ext_sales_price AS ext_sales_price,
        'store' AS channel,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk

    UNION ALL

    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        ws.ws_ext_sales_price AS ext_sales_price,
        'web' AS channel,
        ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
cust_detail AS (
    SELECT
        c.c_customer_sk,
        COALESCE(c.c_first_name, 'UNKNOWN') || ' ' || COALESCE(c.c_last_name, 'UNKNOWN') AS full_name,
        CASE
            WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred'
            WHEN c.c_preferred_cust_flag = 'N' THEN 'Standard'
            ELSE 'Unspecified'
        END AS cust_type,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_avg_profit AS (
    SELECT
        i.i_item_sk,
        AVG(us.net_profit) AS avg_profit_last_quarter
    FROM unified_sales us
    JOIN item i ON us.item_sk = i.i_item_sk
    JOIN date_dim d ON us.date_sk = d.d_date_sk
    WHERE d.d_year = (SELECT MAX(d2.d_year) FROM date_dim d2) - 1
      AND d.d_quarter_seq = (SELECT MAX(d3.d_quarter_seq) FROM date_dim d3 WHERE d3.d_year = d.d_year)
    GROUP BY i.i_item_sk
),
ranked_items AS (
    SELECT
        t.channel,
        t.item_sk,
        t.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY t.channel ORDER BY t.total_net_profit DESC) AS profit_rank,
        SUM(t.total_net_profit) OVER (PARTITION BY t.channel ORDER BY t.total_net_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit
    FROM (
        SELECT us.channel, us.item_sk, SUM(us.net_profit) AS total_net_profit
        FROM unified_sales us
        GROUP BY us.channel, us.item_sk
    ) t
),
channel_totals AS (
    SELECT
        channel,
        SUM(total_net_profit) AS total_channel_profit
    FROM ranked_items
    GROUP BY channel
),
sample_us AS (
    SELECT *
    FROM unified_sales
    ORDER BY rand()
    LIMIT 1
)
SELECT
    r.channel,
    r.item_sk,
    i.i_product_name,
    r.total_net_profit,
    r.profit_rank,
    r.running_profit,
    (r.total_net_profit / NULLIF(ct.total_channel_profit, 0)) * 100 AS profit_pct_of_channel,
    CASE
        WHEN r.total_net_profit > COALESCE(a.avg_profit_last_quarter, 0) THEN 'Above Avg'
        WHEN r.total_net_profit < COALESCE(a.avg_profit_last_quarter, 0) THEN 'Below Avg'
        ELSE 'Equal Avg'
    END AS profit_vs_avg,
    CONCAT('Item ', CAST(r.item_sk AS VARCHAR), ' in ', r.channel, ' channel') AS description,
    COALESCE(c.full_name, 'No Customer') AS sample_customer,
    CASE WHEN REGEXP_LIKE(CONCAT('Item ', CAST(r.item_sk AS VARCHAR)), '\\d0') THEN NULL ELSE CONCAT('Item ', CAST(r.item_sk AS VARCHAR)) END AS maybe_null_desc,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_item_sk = r.item_sk AND ss2.ss_sold_date_sk = su.date_sk) AS store_sales_cnt,
    format_datetime(try(date_parse(CAST(su.date_sk AS VARCHAR), '%Y%m%d')), '%Y-%m-%d') AS pseudo_date_str
FROM ranked_items r
JOIN item i ON r.item_sk = i.i_item_sk
LEFT JOIN item_avg_profit a ON r.item_sk = a.i_item_sk
LEFT JOIN cust_detail c ON r.item_sk = c.c_customer_sk
JOIN channel_totals ct ON r.channel = ct.channel
CROSS JOIN sample_us su
WHERE r.profit_rank <= 10
ORDER BY r.channel, r.profit_rank
