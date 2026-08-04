WITH
returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        d.d_date_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        SUBSTRING(i.i_item_desc FROM 1 FOR 5) AS desc_prefix,
        CONCAT('Item-', i.i_item_id) AS item_code
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '[A-Z]{3}')
      AND i.i_container LIKE 'U%'
    GROUP BY cr.cr_item_sk, d.d_date_sk, i.i_item_desc, i.i_item_id
),
promo_items AS (
    SELECT
        p.p_item_sk AS item_sk,
        d.d_date_sk AS promo_date_sk,
        p.p_promo_id,
        REGEXP_EXTRACT(p.p_promo_name, '(Discount|Clearance)', 1) AS promo_type
    FROM promotion p
    JOIN date_dim d
        ON p.p_start_date_sk = d.d_date_sk
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    WHERE p.p_channel_tv = 'N'
      AND REGEXP_LIKE(p.p_promo_name, '.*(Discount|Clearance).*')
),
diff_items AS (
    SELECT item_sk FROM returns_agg
    EXCEPT
    SELECT item_sk FROM promo_items
),
full_join AS (
    SELECT
        ra.item_sk,
        ra.total_return_amount,
        ra.return_cnt,
        ra.desc_prefix,
        ra.item_code,
        ra.d_date_sk,
        pi.p_promo_id,
        pi.promo_type,
        pi.promo_date_sk
    FROM returns_agg ra
    FULL OUTER JOIN promo_items pi
        ON ra.item_sk = pi.item_sk
),
final AS (
    SELECT
        COALESCE(fj.item_sk, -1) AS item_sk,
        fj.total_return_amount,
        fj.p_promo_id,
        fj.promo_type,
        fj.desc_prefix,
        fj.item_code,
        ROW_NUMBER() OVER (ORDER BY COALESCE(fj.total_return_amount, 0) DESC) AS rn
    FROM full_join fj
    WHERE NOT EXISTS (
        SELECT 1
        FROM store s
        WHERE s.s_closed_date_sk = COALESCE(fj.d_date_sk, fj.promo_date_sk)
          AND s.s_state = 'CA'
    )
)
SELECT *
FROM final
ORDER BY rn
LIMIT 100
