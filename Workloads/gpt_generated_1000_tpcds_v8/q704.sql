WITH cs_agg AS (
    SELECT
        cs_item_sk,
        sum(cs_ext_sales_price) AS total_ext_sales_price,
        count(*) AS catalog_sales_cnt
    FROM catalog_sales
    WHERE cs_ext_sales_price > 100
    GROUP BY cs_item_sk
),
inv_agg AS (
    SELECT
        inv_date_sk,
        sum(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_date_sk
),
cs_detail AS (
    SELECT
        cs_item_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_sold_date_sk,
        cs_ext_sales_price
    FROM catalog_sales
)
SELECT
    d_ss.d_year,
    cd_ss.cd_gender,
    hd_ss.hd_buy_potential,
    cc.cc_name,
    wp.wp_type,
    ib_hd.ib_upper_bound,
    sum(ss.ss_net_paid) AS total_store_net_paid,
    sum(ca.total_ext_sales_price) AS total_catalog_sales_price,
    sum(cs_lat.item_total_sales) AS total_lateral_catalog_price,
    sum(ia.total_qty_on_hand) AS total_inventory_qty
FROM store_sales ss
JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN income_band ib_hd
    ON hd_ss.hd_income_band_sk = ib_hd.ib_income_band_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN cs_agg ca
    ON ca.cs_item_sk = ss.ss_item_sk
JOIN cs_detail csd
    ON csd.cs_item_sk = ss.ss_item_sk
JOIN catalog_page cp
    ON csd.cs_catalog_page_sk = cp.cp_catalog_page_sk
FULL OUTER JOIN call_center cc
    ON cc.cc_open_date_sk = d_ss.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ss.d_date_sk
JOIN inv_agg ia
    ON ia.inv_date_sk = d_ss.d_date_sk
CROSS JOIN LATERAL (
    SELECT sum(cs2.cs_ext_sales_price) AS item_total_sales
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = ss.ss_item_sk
) AS cs_lat
WHERE ss.ss_ticket_number NOT IN (
        SELECT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_return_quantity > 0
    )
  AND ss.ss_item_sk IN (
        SELECT cs_item_sk FROM catalog_sales
        INTERSECT
        SELECT sr_item_sk FROM store_returns
    )
GROUP BY
    d_ss.d_year,
    cd_ss.cd_gender,
    hd_ss.hd_buy_potential,
    cc.cc_name,
    wp.wp_type,
    ib_hd.ib_upper_bound
ORDER BY total_store_net_paid DESC
LIMIT 100
