WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_paid_inc_tax,
        td.t_hour,
        td.t_minute,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        c.c_birth_month,
        hd.hd_income_band_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        cc.cc_name,
        cc.cc_gmt_offset,
        cp.cp_type,
        cp.cp_catalog_page_sk,
        inv.inv_quantity_on_hand,
        wr.wr_reason_sk,
        r.r_reason_desc
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE td.t_hour BETWEEN 9 AND 19
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND c.c_birth_month IN (5, 6, 7)
      AND inv.inv_quantity_on_hand > 500
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
),
q1 AS (
    SELECT *
    FROM base
    WHERE ss_quantity > 2
),
q2 AS (
    SELECT *
    FROM base
    WHERE ss_quantity <= 2
),
union_q AS (
    SELECT * FROM q1
    UNION
    SELECT * FROM q2
),
intersect_q AS (
    SELECT ss_item_sk
    FROM union_q
    INTERSECT
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 600
),
final AS (
    SELECT
        uq.s_store_id,
        uq.s_store_name,
        uq.i_item_id,
        uq.i_brand,
        uq.ss_net_paid_inc_tax,
        uq.r_reason_desc,
        uq.t_hour,
        ROW_NUMBER() OVER (PARTITION BY uq.s_store_id ORDER BY uq.ss_net_paid_inc_tax DESC) AS rn,
        CASE
            WHEN uq.ss_net_paid_inc_tax > (
                SELECT MAX(cs.cs_net_paid_inc_ship_tax)
                FROM catalog_sales cs
                WHERE cs.cs_item_sk = uq.ss_item_sk
            ) THEN 1 ELSE 0
        END AS high_vs_catalog_max
    FROM union_q uq
    WHERE uq.ss_item_sk IN (SELECT ss_item_sk FROM intersect_q)
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp
          WHERE cp.cp_type = 'PROMO'
            AND cp.cp_catalog_page_sk = uq.cp_catalog_page_sk
      )
)
SELECT
    s_store_id,
    s_store_name,
    i_item_id,
    i_brand,
    ss_net_paid_inc_tax,
    r_reason_desc,
    t_hour,
    rn,
    high_vs_catalog_max
FROM final
ORDER BY rn, s_store_id
LIMIT 100
