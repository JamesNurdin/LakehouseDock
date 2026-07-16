WITH store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ca.ca_state AS region,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        MAX(d.d_date) AS last_sale_date,
        AVG(CASE WHEN ss.ss_ext_sales_price > 0 THEN ss.ss_ext_discount_amt / ss.ss_ext_sales_price ELSE NULL END) AS avg_discount_ratio,
        AVG(p.p_cost) AS avg_promo_cost
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY 1,2
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ca.ca_state AS region,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        MAX(d.d_date) AS last_sale_date,
        AVG(CASE WHEN ws.ws_ext_sales_price > 0 THEN ws.ws_ext_discount_amt / ws.ws_ext_sales_price ELSE NULL END) AS avg_discount_ratio,
        AVG(p.p_cost) AS avg_promo_cost
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 1,2
),
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        ca.ca_state AS region,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        MAX(d.d_date) AS last_sale_date,
        AVG(CASE WHEN cs.cs_ext_sales_price > 0 THEN cs.cs_ext_discount_amt / cs.cs_ext_sales_price ELSE NULL END) AS avg_discount_ratio,
        AVG(p.p_cost) AS avg_promo_cost
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY 1,2
),
combined_sales AS (
    SELECT customer_sk, region, total_sales, total_profit, total_quantity, last_sale_date, avg_discount_ratio, avg_promo_cost
    FROM store_sales_agg
    UNION ALL
    SELECT customer_sk, region, total_sales, total_profit, total_quantity, last_sale_date, avg_discount_ratio, avg_promo_cost
    FROM web_sales_agg
    UNION ALL
    SELECT customer_sk, region, total_sales, total_profit, total_quantity, last_sale_date, avg_discount_ratio, avg_promo_cost
    FROM catalog_sales_agg
),
sales_by_customer AS (
    SELECT
        customer_sk,
        region,
        SUM(total_sales) AS total_sales,
        SUM(total_profit) AS total_profit,
        SUM(total_quantity) AS total_quantity,
        MAX(last_sale_date) AS last_sale_date,
        AVG(avg_discount_ratio) AS avg_discount_ratio,
        AVG(avg_promo_cost) AS avg_promo_cost
    FROM combined_sales
    GROUP BY 1,2
),
dual_channel_customers AS (
    SELECT customer_sk FROM store_sales_agg
    INTERSECT
    SELECT customer_sk FROM web_sales_agg
),
returns_agg AS (
    SELECT
        COALESCE(sr.sr_customer_sk, wr.wr_refunded_customer_sk) AS customer_sk,
        COUNT(*) AS return_count,
        SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_return_loss
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr
        ON sr.sr_customer_sk = wr.wr_refunded_customer_sk
    GROUP BY 1
),
final AS (
    SELECT
        s.customer_sk,
        c.c_customer_id AS customer_id,
        s.region,
        s.total_sales,
        s.total_profit,
        s.total_quantity,
        s.last_sale_date,
        COALESCE(r.return_count, 0) AS return_count,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = s.customer_sk) AS catalog_return_count,
        ROW_NUMBER() OVER (PARTITION BY s.region ORDER BY s.total_sales DESC) AS region_rank,
        SUM(s.total_sales) OVER (PARTITION BY s.region ORDER BY s.total_sales DESC) AS cum_sales_region,
        CASE
            WHEN s.total_sales > (SELECT AVG(total_sales) FROM sales_by_customer) THEN 'HIGH'
            WHEN s.total_sales BETWEEN (SELECT AVG(total_sales) * 0.5 FROM sales_by_customer) AND (SELECT AVG(total_sales) FROM sales_by_customer) THEN 'MEDIUM'
            ELSE 'LOW'
        END AS sales_category,
        CONCAT('Cust-', COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, ''), ' (', COALESCE(c.c_email_address, ''), ')') AS customer_desc,
        DATE_DIFF('day', s.last_sale_date, DATE '2024-10-01') AS days_since_last_sale,
        COALESCE(s.avg_promo_cost, 0) AS avg_promo_cost
    FROM sales_by_customer s
    LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
    LEFT JOIN returns_agg r ON s.customer_sk = r.customer_sk
    WHERE s.customer_sk IN (SELECT customer_sk FROM dual_channel_customers)
)
SELECT *
FROM final
WHERE region_rank <= 10
ORDER BY region, region_rank
