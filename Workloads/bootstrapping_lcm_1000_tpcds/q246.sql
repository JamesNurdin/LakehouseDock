WITH base AS (
    SELECT
        d.d_date,
        s.s_store_name,
        s.s_manager,
        i.i_category,
        i.i_brand,
        SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(cr.cr_net_loss + wr.wr_net_loss) AS total_net_loss,
        AVG(i.i_current_price) AS avg_item_price,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_catalog_customers,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS distinct_web_customers
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY d.d_date, s.s_store_name, s.s_manager, i.i_category, i.i_brand
)
SELECT
    d_date,
    s_store_name,
    s_manager,
    i_category,
    i_brand,
    total_catalog_return_qty,
    total_web_return_qty,
    catalog_net_loss,
    web_net_loss,
    total_net_loss,
    avg_item_price,
    distinct_catalog_customers,
    distinct_web_customers,
    CASE
        WHEN (total_catalog_return_qty + total_web_return_qty) > 0
        THEN total_net_loss / (total_catalog_return_qty + total_web_return_qty)
        ELSE 0
    END AS loss_per_return,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM base
ORDER BY net_loss_rank
LIMIT 100
