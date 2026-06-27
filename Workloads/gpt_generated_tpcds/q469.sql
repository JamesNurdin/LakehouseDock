WITH sales AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        sum(ws.ws_ext_sales_price) AS total_sales,
        sum(ws.ws_ext_discount_amt) AS total_discount,
        sum(ws.ws_net_profit) AS total_profit,
        count(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        count(DISTINCT ws.ws_promo_sk) AS promo_count,
        avg(ws.ws_ext_discount_amt / nullif(ws.ws_ext_sales_price, 0)) AS avg_discount_rate,
        avg(p.p_cost) AS avg_promo_cost
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk AND p.p_discount_active = 'Y'
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_category
),
returns AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        sum(wr.wr_return_amt) AS total_returns,
        sum(wr.wr_return_tax) AS total_return_tax,
        sum(wr.wr_fee) AS total_return_fee
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_category
)
SELECT
    s.d_year,
    s.d_moy,
    s.i_category,
    s.total_sales,
    coalesce(r.total_returns, 0) AS total_returns,
    s.total_sales - coalesce(r.total_returns, 0) AS net_sales,
    s.total_discount,
    s.total_profit,
    s.distinct_customers,
    s.promo_count,
    s.avg_discount_rate,
    s.avg_promo_cost
FROM sales s
LEFT JOIN returns r
    ON s.d_year = r.d_year
   AND s.d_moy = r.d_moy
   AND s.i_category = r.i_category
ORDER BY s.d_year, s.d_moy, s.i_category
