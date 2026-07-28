WITH returns_raw AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_returned_time_sk AS time_sk,
        cr.cr_ship_mode_sk AS ship_mode_sk,
        cr.cr_refunded_addr_sk AS address_sk,
        cr.cr_refunded_cdemo_sk AS cd_demo_sk,
        cr.cr_refunded_hdemo_sk AS hd_demo_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_tax AS return_tax,
        cr.cr_fee AS fee,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS quantity,
        'catalog' AS source
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
      AND cr.cr_return_quantity >= 1
      AND cr.cr_returned_date_sk BETWEEN 2450815 AND 2451170
      AND cr.cr_refunded_addr_sk IS NOT NULL
    UNION ALL
    SELECT
        wr.wr_item_sk AS item_sk,
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_returned_time_sk AS time_sk,
        NULL AS ship_mode_sk,
        wr.wr_refunded_addr_sk AS address_sk,
        wr.wr_refunded_cdemo_sk AS cd_demo_sk,
        wr.wr_refunded_hdemo_sk AS hd_demo_sk,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_tax AS return_tax,
        wr.wr_fee AS fee,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS quantity,
        'web' AS source
    FROM web_returns wr
    WHERE wr.wr_return_amt > 0
      AND wr.wr_return_quantity >= 1
      AND wr.wr_returned_date_sk BETWEEN 2450815 AND 2451170
      AND wr.wr_refunded_addr_sk IS NOT NULL
),
agg1 AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_brand AS brand,
        SUM(r.return_amount) AS total_return_amount,
        SUM(r.return_tax) AS total_return_tax,
        SUM(r.fee) AS total_fee,
        SUM(r.net_loss) AS total_net_loss,
        SUM(r.quantity) AS total_quantity,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(r.return_amount) > 10000 THEN 'HIGH'
            WHEN SUM(r.return_amount) > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_level
    FROM returns_raw r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN time_dim t ON r.time_sk = t.t_time_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm ON r.ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON r.address_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON r.cd_demo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON r.hd_demo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE ca.ca_state = 'CA'
      AND ca.ca_zip LIKE '90%'
      AND i.i_current_price BETWEEN 10 AND 100
      AND sm.sm_type = 'AIR'
      AND t.t_meal_time = 'lunch'
      AND d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM web_site ws
          WHERE ws.web_open_date_sk = d.d_date_sk
            AND ws.web_site_id = 'WS_001'
      )
    GROUP BY d.d_year, i.i_category, i.i_brand
),
agg2 AS (
    SELECT
        year,
        category,
        brand,
        total_return_amount,
        SUM(total_return_amount) OVER (PARTITION BY year) AS yearly_total_return,
        AVG(total_return_amount) OVER (PARTITION BY category) AS avg_return_per_category,
        return_level
    FROM agg1
)
SELECT
    year,
    category,
    brand,
    total_return_amount,
    yearly_total_return,
    avg_return_per_category,
    return_level
FROM agg2
WHERE yearly_total_return > 50000
ORDER BY total_return_amount DESC
LIMIT 100
