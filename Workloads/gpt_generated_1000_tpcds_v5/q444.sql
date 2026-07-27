WITH returns_agg AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        sm.sm_type,
        p.p_promo_name,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_orders
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd_wr_refunded
        ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    JOIN customer_address ca_wr_refunded
        ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    WHERE
        td.t_hour BETWEEN 8 AND 18
        AND i.i_current_price > 50
        AND p.p_channel_email = 'Y'
        AND sm.sm_type = 'EXPRESS'
    GROUP BY
        i.i_item_id,
        i.i_brand,
        sm.sm_type,
        p.p_promo_name
)
SELECT
    brand,
    AVG(catalog_net_loss) AS avg_catalog_loss,
    AVG(web_net_loss) AS avg_web_loss,
    SUM(catalog_return_qty + web_return_qty) AS total_returns
FROM (
    SELECT
        i_brand AS brand,
        sm_type,
        catalog_net_loss,
        web_net_loss,
        catalog_return_qty,
        web_return_qty
    FROM returns_agg
) sub
GROUP BY brand
HAVING SUM(catalog_return_qty + web_return_qty) > 10
ORDER BY avg_catalog_loss DESC
LIMIT 100
