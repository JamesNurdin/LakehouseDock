WITH per_group AS (
    SELECT
        ss.ss_customer_sk AS c_customer_sk,
        ss.ss_item_sk AS i_item_sk,
        i.i_brand AS brand,
        i.i_category AS category,
        ca.ca_county AS county,
        p.p_purpose AS promo_purpose,
        p.p_channel_catalog AS promo_channel,
        wp.wp_url AS wp_url,
        SUM(ss.ss_net_profit) AS sum_net_profit,
        COALESCE(SUM(wr.wr_return_amt), 0) AS sum_return_amt,
        SUM(ss.ss_quantity) AS sum_quantity,
        SUM(inv.inv_quantity_on_hand) AS sum_inventory,
        SUM(ss.ss_net_profit) - COALESCE(SUM(wr.wr_return_amt), 0) AS net_gain
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv
        ON ss.ss_item_sk = inv.inv_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON c.c_customer_sk = wp.wp_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE p.p_purpose = 'Unknown'
      AND p.p_channel_catalog = 'N'
      AND ca.ca_county IN ('Maricopa County', 'Chelan County')
      AND i.i_brand IS NOT NULL
      AND inv.inv_quantity_on_hand > 0
      AND p.p_response_target = 1
      AND ss.ss_sold_date_sk > 2451910
    GROUP BY
        ss.ss_customer_sk,
        ss.ss_item_sk,
        i.i_brand,
        i.i_category,
        ca.ca_county,
        p.p_purpose,
        p.p_channel_catalog,
        wp.wp_url
),
group_summary AS (
    SELECT
        brand,
        category,
        county,
        COUNT(*) AS num_groups,
        SUM(sum_net_profit) AS total_net_profit,
        SUM(sum_return_amt) AS total_return_amount,
        SUM(net_gain) AS net_gain,
        AVG(sum_net_profit) AS avg_net_profit,
        AVG(sum_return_amt) AS avg_return_amount,
        AVG(net_gain) AS avg_net_gain,
        MIN(wp_url) AS wp_url
    FROM per_group
    GROUP BY brand, category, county
)
SELECT
    gs.brand,
    gs.category,
    gs.county,
    gs.num_groups,
    gs.net_gain,
    url_segment
FROM group_summary gs
CROSS JOIN UNNEST(split(gs.wp_url, '/')) AS t(url_segment)
WHERE EXISTS (
    SELECT 1
    FROM per_group pg
    WHERE pg.brand = gs.brand
      AND pg.category = gs.category
      AND pg.county = gs.county
      AND pg.net_gain > 0
)
  AND gs.net_gain > 1000
ORDER BY gs.net_gain DESC
LIMIT 100
