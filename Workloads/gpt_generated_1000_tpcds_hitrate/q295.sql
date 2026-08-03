WITH joined_data AS (
    SELECT
        d_ret.d_year AS return_year,
        d_sale.d_year AS sale_year,
        p.p_promo_id,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ws.ws_net_profit,
        cust.c_customer_sk,
        p.p_discount_active
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = cust.c_customer_sk
    JOIN date_dim d_sale ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    WHERE d_ret.d_year = 2001
      AND d_sale.d_year BETWEEN 2001 AND 2002
      AND hd.hd_dep_count BETWEEN 2 AND 6
      AND p.p_discount_active = 'Y'
      AND ws.ws_net_paid_inc_ship_tax > 1000
      AND cr.cr_return_amount > 0
),
agg AS (
    SELECT
        return_year,
        p_promo_id,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers,
        COUNT(DISTINCT p_promo_id) AS distinct_promos,
        SUM(CASE WHEN ws_net_profit > 0 THEN 1 ELSE 0 END) AS profitable_sales_cnt
    FROM joined_data
    GROUP BY return_year, p_promo_id
)
SELECT
    return_year,
    AVG(total_net_profit) AS avg_profit_per_promo,
    SUM(total_net_loss) AS sum_net_loss,
    COUNT(DISTINCT p_promo_id) AS promo_count,
    SUM(profitable_sales_cnt) AS total_profitable_sales
FROM agg
GROUP BY return_year
HAVING SUM(total_net_loss) > 5000
ORDER BY return_year DESC
LIMIT 100
