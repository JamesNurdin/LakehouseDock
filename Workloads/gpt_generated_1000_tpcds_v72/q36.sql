WITH cat_agg AS (
    SELECT
        cr.cr_refunded_hdemo_sk AS hd_demo_sk,
        SUM(cr.cr_net_loss) AS net_loss,
        SUM(cr.cr_return_quantity) AS return_qty
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 1000
      AND cr.cr_return_quantity >= 1
    GROUP BY cr.cr_refunded_hdemo_sk
),
web_agg AS (
    SELECT
        wr.wr_refunded_hdemo_sk AS hd_demo_sk,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(wr.wr_return_quantity) AS return_qty
    FROM web_returns wr
    WHERE wr.wr_return_ship_cost < 500
      AND wr.wr_return_tax > 20
    GROUP BY wr.wr_refunded_hdemo_sk
),
combined AS (
    SELECT hd_demo_sk, net_loss, return_qty, 'catalog' AS src FROM cat_agg
    UNION ALL
    SELECT hd_demo_sk, net_loss, return_qty, 'web' AS src FROM web_agg
),
agg_final AS (
    SELECT
        hd_demo_sk,
        SUM(net_loss) AS total_net_loss,
        SUM(return_qty) AS total_return_qty
    FROM combined
    GROUP BY hd_demo_sk
),
addr_map AS (
    SELECT DISTINCT cr.cr_refunded_hdemo_sk AS hd_demo_sk, cr.cr_refunded_addr_sk AS addr_sk
    FROM catalog_returns cr
    UNION
    SELECT DISTINCT wr.wr_refunded_hdemo_sk, wr.wr_refunded_addr_sk
    FROM web_returns wr
)
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    ca.ca_location_type,
    ca.ca_country,
    a.total_net_loss,
    a.total_return_qty,
    RANK() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank
FROM agg_final a
JOIN household_demographics hd ON a.hd_demo_sk = hd.hd_demo_sk
JOIN addr_map am ON a.hd_demo_sk = am.hd_demo_sk
JOIN customer_address ca ON am.addr_sk = ca.ca_address_sk
WHERE hd.hd_dep_count BETWEEN 2 AND 5
  AND hd.hd_buy_potential = '5001-10000'
  AND hd.hd_vehicle_count >= 0
  AND ca.ca_location_type = 'condo'
  AND ca.ca_country = 'United States'
ORDER BY loss_rank
LIMIT 100
