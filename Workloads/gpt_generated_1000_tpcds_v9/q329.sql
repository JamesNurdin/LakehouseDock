WITH store_sales_agg AS (
    SELECT
        i_l.i_item_id AS item_id,
        i_l.i_category AS category,
        s.s_store_name AS source_name,
        td.t_hour AS hour,
        SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    CROSS JOIN LATERAL (
        SELECT i.i_item_id, i.i_category
        FROM item i
        WHERE i.i_item_sk = ss.ss_item_sk
    ) i_l
    WHERE td.t_hour BETWEEN 9 AND 17
      AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_ticket_number = ss.ss_ticket_number
              AND sr.sr_item_sk = ss.ss_item_sk
        )
    GROUP BY i_l.i_item_id, i_l.i_category, s.s_store_name, td.t_hour
),
catalog_sales_agg AS (
    SELECT
        i_l.i_item_id AS item_id,
        i_l.i_category AS category,
        cc.cc_name AS source_name,
        td.t_hour AS hour,
        SUM(cs.cs_net_paid) AS total_sales
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    CROSS JOIN LATERAL (
        SELECT i.i_item_id, i.i_category
        FROM item i
        WHERE i.i_item_sk = cs.cs_item_sk
    ) i_l
    WHERE td.t_hour BETWEEN 9 AND 17
      AND cc.cc_state = 'CA'
    GROUP BY i_l.i_item_id, i_l.i_category, cc.cc_name, td.t_hour
)
SELECT *
FROM (
    SELECT item_id, category, source_name, total_sales, hour FROM store_sales_agg
    UNION
    SELECT item_id, category, source_name, total_sales, hour FROM catalog_sales_agg
) AS combined
ORDER BY total_sales DESC, item_id
LIMIT 100
