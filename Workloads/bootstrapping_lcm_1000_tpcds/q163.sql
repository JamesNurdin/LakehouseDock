WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_return.d_year,
        d_return.d_quarter_name,
        SUM(cs.cs_net_profit) AS total_catalog_net_profit,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        SUM(cs.cs_ext_ship_cost) AS total_catalog_shipping_cost,
        SUM(cr.cr_return_ship_cost) AS total_catalog_return_shipping_cost,
        SUM(wr.wr_return_ship_cost) AS total_web_return_shipping_cost,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_days_to_ship,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_returns,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_web_returns
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_return.d_date_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    WHERE d_return.d_year = 2001
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, s.s_store_name, d_return.d_year, d_return.d_quarter_name
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.d_year,
    agg.d_quarter_name,
    agg.total_catalog_net_profit,
    agg.total_catalog_net_loss,
    agg.total_web_net_loss,
    agg.total_catalog_shipping_cost,
    agg.total_catalog_return_shipping_cost,
    agg.total_web_return_shipping_cost,
    agg.avg_days_to_ship,
    agg.distinct_catalog_orders,
    agg.distinct_catalog_returns,
    agg.distinct_web_returns,
    RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.total_catalog_net_profit DESC) AS yearly_profit_rank
FROM agg
ORDER BY agg.total_catalog_net_profit DESC
LIMIT 100
