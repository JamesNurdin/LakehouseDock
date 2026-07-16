SELECT
    agg.d_year,
    agg.d_month_seq,
    agg.s_store_name,
    agg.s_state,
    agg.web_name,
    agg.web_state,
    agg.total_return_amount,
    agg.total_net_loss,
    agg.avg_inventory_on_hand,
    agg.distinct_orders,
    CASE WHEN agg.total_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_category,
    RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.total_return_amount DESC) AS store_return_rank
FROM (
    SELECT
        dd.d_year,
        dd.d_month_seq,
        s.s_store_name,
        s.s_state,
        ws.web_name,
        ws.web_state,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN date_dim dd
        ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = dd.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = dd.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 1999 AND 2001
      AND inv.inv_quantity_on_hand > 0
      AND s.s_state IS NOT NULL
      AND ws.web_state IS NOT NULL
    GROUP BY
        dd.d_year,
        dd.d_month_seq,
        s.s_store_name,
        s.s_state,
        ws.web_name,
        ws.web_state
) agg
ORDER BY agg.d_year, store_return_rank
LIMIT 100
