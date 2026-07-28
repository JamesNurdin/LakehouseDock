/*
Goal: Summarize catalog sales and store returns by warehouse (for sales) and by store (for returns),
including gender and hour of day, while applying realistic filters, using a left‑join to inventory,
building two aggregated sub‑queries and uniting them.
*/
WITH sales_agg AS (
    SELECT
        CAST(NULL AS varchar)                                   AS store_name,
        w.w_warehouse_name                                      AS warehouse_name,
        cd.cd_gender                                            AS gender,
        td.t_hour                                               AS hour,
        SUM(cs.cs_ext_sales_price)                              AS total_sales,
        CAST(NULL AS decimal(7,2))                              AS total_returns,
        COUNT(*)                                                AS sales_cnt,
        CAST(NULL AS integer)                                   AS returns_cnt,
        AVG(p.p_cost)                                           AS avg_promo_cost,
        CAST(NULL AS decimal(7,2))                              AS avg_return_loss,
        MIN(inv.inv_quantity_on_hand)                           AS min_inventory,
        MAX(w.w_warehouse_sq_ft)                                AS max_warehouse_sq_ft
    FROM catalog_sales cs
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
         AND inv.inv_item_sk = cs.cs_item_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_ext_sales_price > 500
      AND cd.cd_gender = 'M'
      AND td.t_hour = 14
    GROUP BY w.w_warehouse_name, cd.cd_gender, td.t_hour
),
returns_agg AS (
    SELECT
        s.s_store_name                                          AS store_name,
        CAST(NULL AS varchar)                                   AS warehouse_name,
        cd.cd_gender                                            AS gender,
        td.t_hour                                               AS hour,
        CAST(NULL AS decimal(7,2))                              AS total_sales,
        SUM(sr.sr_return_amt)                                   AS total_returns,
        CAST(NULL AS integer)                                   AS sales_cnt,
        COUNT(*)                                                AS returns_cnt,
        CAST(NULL AS decimal(7,2))                              AS avg_promo_cost,
        AVG(sr.sr_net_loss)                                     AS avg_return_loss,
        CAST(NULL AS integer)                                   AS min_inventory,
        CAST(NULL AS integer)                                   AS max_warehouse_sq_ft
    FROM store_returns sr
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim td
      ON sr.sr_return_time_sk = td.t_time_sk
    WHERE sr.sr_return_amt > 100
      AND cd.cd_gender = 'F'
      AND s.s_rec_start_date >= DATE '2002-01-01'
      AND td.t_hour = 14
    GROUP BY s.s_store_name, cd.cd_gender, td.t_hour
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY total_sales DESC NULLS LAST, total_returns DESC NULLS LAST
LIMIT 100
