WITH sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_promo_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cd.cd_education_status = 'College'
      AND p.p_purpose = 'Unknown'
),
returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_ticket_number,
        sr.sr_return_amt,
        r.r_reason_desc
    FROM tpcds.store_returns sr
    JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
),
web_ret AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_amt,
        r.r_reason_desc AS web_reason_desc
    FROM tpcds.web_returns wr
    JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
)
SELECT
    s.s_store_id,
    d.d_year,
    SUM(sales.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT sales.ss_ticket_number) AS total_transactions,
    CASE
        WHEN SUM(sales.ss_net_profit) > 100000 THEN 'High'
        WHEN SUM(sales.ss_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    COALESCE(SUM(returns.sr_return_amt), 0) AS store_return_amount,
    COALESCE(SUM(web_ret.wr_return_amt), 0) AS web_return_amount,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(sales.ss_net_profit) DESC) AS profit_rank
FROM sales
JOIN tpcds.store s ON sales.ss_store_sk = s.s_store_sk
JOIN tpcds.date_dim d ON sales.ss_sold_date_sk = d.d_date_sk
LEFT JOIN returns ON sales.ss_ticket_number = returns.sr_ticket_number
    AND sales.ss_store_sk = returns.sr_store_sk
LEFT JOIN web_ret ON sales.ss_sold_date_sk = web_ret.wr_returned_date_sk
GROUP BY
    s.s_store_id,
    d.d_year
ORDER BY profit_rank
LIMIT 100
