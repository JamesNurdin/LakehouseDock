WITH returns_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_refunded_cdemo_sk,
        i.i_item_id,
        i.i_category,
        i.i_formulation,
        i.i_item_desc,
        i.i_brand,
        i.i_color,
        cd.cd_gender,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_product_name LIKE '%Gold%'
      AND regexp_like(i.i_formulation, '^\\d+')
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_item_sk = i.i_item_sk
            AND ws2.ws_ship_cdemo_sk = cd.cd_demo_sk
      )
    GROUP BY
        cr.cr_item_sk,
        cr.cr_refunded_cdemo_sk,
        i.i_item_id,
        i.i_category,
        i.i_formulation,
        i.i_item_desc,
        i.i_brand,
        i.i_color,
        cd.cd_gender
)
SELECT
    ra.i_item_id,
    ra.cd_gender,
    ra.total_return_loss,
    ra.return_cnt,
    regexp_extract(ra.i_formulation, '(\\d+)', 1) AS formulation_number,
    substring(ra.i_item_desc, 1, 10) AS short_desc,
    concat(ra.i_brand, ' ', ra.i_color) AS brand_color,
    (
        SELECT SUM(ws.ws_ext_sales_price)
        FROM web_sales ws
        WHERE ws.ws_item_sk = ra.cr_item_sk
          AND ws.ws_bill_cdemo_sk = ra.cr_refunded_cdemo_sk
    ) AS total_sales_amount,
    rank() OVER (PARTITION BY ra.i_category ORDER BY ra.total_return_loss DESC) AS loss_rank
FROM returns_agg ra
ORDER BY ra.total_return_loss DESC
