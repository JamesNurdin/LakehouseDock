WITH reason_aggregates AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_id,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        SUM(wr.wr_net_loss) AS total_web_net_loss
    FROM reason r
    LEFT JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)return') OR r.r_reason_desc LIKE '%damage%'
    GROUP BY r.r_reason_sk, r.r_reason_id, r.r_reason_desc
)
SELECT
    ra.r_reason_id,
    ra.r_reason_desc,
    regexp_extract(ra.r_reason_id, '^(.{3})', 1) AS reason_id_prefix,
    CASE WHEN regexp_like(ra.r_reason_desc, '(?i)damage') THEN 1 ELSE 0 END AS is_damage,
    ra.total_store_net_loss,
    ra.total_web_net_loss,
    (
        SELECT COUNT(DISTINCT i.inv_item_sk)
        FROM inventory i
        JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
        WHERE w.w_warehouse_name LIKE CONCAT(SUBSTR(ra.r_reason_id, 1, 1), '%')
    ) AS matching_inventory_item_cnt,
    ROW_NUMBER() OVER (ORDER BY ra.total_store_net_loss DESC) AS rn
FROM reason_aggregates ra
ORDER BY rn
LIMIT 100
