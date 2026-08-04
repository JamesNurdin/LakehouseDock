WITH
    -- items that were sold in the catalog but never returned in a store
    sold_not_returned AS (
        SELECT i_item_sk
        FROM item
        EXCEPT
        SELECT sr_item_sk
        FROM store_returns
    ),

    -- join all selected tables applying several filters
    base AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_item_sk,
            cs.cs_quantity,
            cs.cs_net_paid,
            i.i_category,
            i.i_brand,
            i.i_current_price,
            cd.cd_gender,
            cd.cd_credit_rating,
            hd.hd_vehicle_count,
            cc.cc_name,
            sr.sr_return_quantity,
            ws.ws_net_paid            AS ws_net_paid,
            wp.wp_char_count,
            ws_site.web_name          AS web_site_name,
            inv.inv_quantity_on_hand,
            p.p_promo_name,
            wr.wr_return_quantity,
            wr.wr_return_amt
        FROM catalog_sales cs
        JOIN item i                     ON cs.cs_item_sk      = i.i_item_sk
        JOIN customer_demographics cd   ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN call_center cc             ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN promotion p           ON cs.cs_promo_sk     = p.p_promo_sk
        LEFT JOIN store_returns sr      ON sr.sr_item_sk      = i.i_item_sk
        LEFT JOIN store s               ON sr.sr_store_sk     = s.s_store_sk
        LEFT JOIN web_sales ws          ON ws.ws_item_sk      = i.i_item_sk
        LEFT JOIN web_page wp           ON ws.ws_web_page_sk  = wp.wp_web_page_sk
        LEFT JOIN web_site ws_site      ON ws.ws_web_site_sk  = ws_site.web_site_sk
        LEFT JOIN inventory inv         ON inv.inv_item_sk    = i.i_item_sk
        LEFT JOIN web_returns wr       ON wr.wr_item_sk      = i.i_item_sk
                                         AND wr.wr_order_number = ws.ws_order_number
        WHERE cs.cs_item_sk IN (SELECT i_item_sk FROM sold_not_returned)
          AND cs.cs_sold_date_sk BETWEEN 2451074 AND 2451095
          AND i.i_wholesale_cost > 5.0
          AND cd.cd_credit_rating = 'Good'
          AND hd.hd_vehicle_count >= 2
    ),

    -- first level aggregation using GROUPING SETS
    agg AS (
        SELECT
            COALESCE(i_category, 'ALL') AS category,
            cd_gender,
            SUM(cs_quantity)            AS total_qty,
            SUM(cs_net_paid)            AS total_net_paid,
            SUM(ws_net_paid)            AS total_ws_net_paid,
            GROUPING(i_category)        AS grp_category,
            GROUPING(cd_gender)         AS grp_gender
        FROM base
        GROUP BY GROUPING SETS (
            (i_category, cd_gender),
            (cd_gender),
            ()
        )
    ),

    -- a tiny computed set to cross‑join with
    flags AS (
        SELECT 1 AS flag UNION ALL SELECT 2 UNION ALL SELECT 3
    ),

    -- cartesian product between the aggregates and the flags
    crossed AS (
        SELECT a.*, f.flag
        FROM agg a
        CROSS JOIN flags f
    ),

    -- final aggregation, also using a scalar sub‑query
    final AS (
        SELECT
            flag,
            AVG(total_net_paid)                     AS avg_total_net_paid,
            SUM(total_qty)                           AS sum_qty,
            (SELECT AVG(i_current_price) FROM item) AS overall_avg_price
        FROM crossed
        GROUP BY flag
        HAVING SUM(total_qty) > 0
    )
SELECT
    flag,
    avg_total_net_paid,
    sum_qty,
    overall_avg_price
FROM final
ORDER BY flag
OFFSET 0 FETCH NEXT 100 ROWS ONLY
