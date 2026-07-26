WITH sales AS (
    SELECT
        p.p_promo_name,
        ca.ca_state,
        SUM(cs.cs_net_profit) AS sales_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN customer_address ca
        ON cs.cs_ship_addr_sk = ca.ca_address_sk
    GROUP BY p.p_promo_name, ca.ca_state
),
returns AS (
    SELECT
        p.p_promo_name,
        ca.ca_state,
        SUM(wr.wr_net_loss) AS return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    INNER JOIN promotion p
        ON wr.wr_item_sk = p.p_item_sk
    INNER JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY p.p_promo_name, ca.ca_state
)
SELECT
    s.p_promo_name,
    s.ca_state,
    s.sales_profit,
    COALESCE(r.return_loss, 0) AS return_loss,
    s.sales_profit - COALESCE(r.return_loss, 0) AS net_profit,
    CASE WHEN s.sales_cnt > 0 THEN s.sales_profit / s.sales_cnt END AS profit_per_sale,
    CASE WHEN r.return_cnt > 0 THEN r.return_loss / r.return_cnt END AS loss_per_return,
    PERCENT_RANK() OVER (ORDER BY s.sales_profit - COALESCE(r.return_loss, 0)) AS profit_percentile,
    DENSE_RANK() OVER (ORDER BY s.sales_profit - COALESCE(r.return_loss, 0) DESC) AS profit_rank
FROM sales s
LEFT JOIN returns r
    ON s.p_promo_name = r.p_promo_name
    AND s.ca_state = r.ca_state
ORDER BY net_profit DESC
LIMIT 15
