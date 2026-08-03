WITH catalog_orders AS (
    SELECT cr.cr_order_number AS order_id,
           cr.cr_net_loss AS net_loss,
           cr.cr_reason_sk,
           i.i_product_name
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, 'Pack')
),
store_orders AS (
    SELECT sr.sr_ticket_number AS order_id,
           sr.sr_net_loss AS net_loss,
           sr.sr_reason_sk,
           i.i_product_name
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, 'Pack')
),
union_orders AS (
    SELECT order_id, net_loss, cr_reason_sk AS reason_sk FROM catalog_orders
    UNION
    SELECT order_id, net_loss, sr_reason_sk AS reason_sk FROM store_orders
),
intersect_orders AS (
    SELECT ws.ws_order_number AS order_id
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 500
    INTERSECT
    SELECT wr.wr_order_number AS order_id
    FROM web_returns wr
    WHERE wr.wr_return_amt > 100
),
except_orders AS (
    SELECT cr.cr_order_number AS order_id
    FROM catalog_returns cr
    WHERE cr.cr_net_loss < 0
    EXCEPT
    SELECT sr.sr_ticket_number AS order_id
    FROM store_returns sr
    WHERE sr.sr_net_loss < 0
),
filtered_union AS (
    SELECT u.order_id,
           u.net_loss,
           u.reason_sk
    FROM union_orders u
    WHERE u.order_id IN (SELECT order_id FROM intersect_orders)
      AND u.order_id NOT IN (SELECT order_id FROM except_orders)
),
final_agg AS (
    SELECT
        regexp_extract(r.r_reason_desc, '(\\w+)') AS reason_first_word,
        COUNT(DISTINCT fu.order_id) AS distinct_orders,
        SUM(fu.net_loss) AS total_net_loss,
        CONCAT('Reason: ', r.r_reason_desc) AS full_reason_text,
        SUBSTRING(r.r_reason_desc FROM 1 FOR 10) AS reason_prefix
    FROM filtered_union fu
    JOIN reason r ON fu.reason_sk = r.r_reason_sk
    JOIN LATERAL (
        SELECT lower(r.r_reason_desc) AS lower_desc
    ) AS ld ON true
    WHERE regexp_like(ld.lower_desc, 'working')
      AND r.r_reason_desc LIKE '%time%'
    GROUP BY regexp_extract(r.r_reason_desc, '(\\w+)'),
             r.r_reason_desc
    HAVING COUNT(*) > 5
)
SELECT reason_first_word,
       distinct_orders,
       total_net_loss,
       full_reason_text,
       reason_prefix
FROM final_agg
LIMIT 100
