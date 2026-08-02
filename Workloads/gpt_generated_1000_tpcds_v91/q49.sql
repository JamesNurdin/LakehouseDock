WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        i.i_category,
        i.i_brand,
        s.s_store_id AS s_store_id,
        s.s_state,
        s.s_division_id,
        p.p_discount_active,
        sm.sm_type,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ca.ca_city,
        ss.ss_net_profit,
        sr.sr_net_loss AS returns_net_loss,
        cr.cr_net_loss AS catalog_net_loss,
        ws.ws_net_profit AS web_net_profit,
        ss.ss_quantity,
        sr.sr_return_quantity,
        cr.cr_return_quantity,
        ws.ws_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_state = 'CA'
      AND s.s_division_id = 1
      AND p.p_discount_active = 'Y'
      AND (cr.cr_reason_sk IS NULL OR cr.cr_reason_sk IN (9, 13))
      AND (sm.sm_type IS NULL OR sm.sm_type = 'AIR')
      AND ss.ss_quantity > 5
),
aggregated AS (
    SELECT
        s_store_id,
        i_category,
        SUM(ss_net_profit) AS sales_net_profit,
        SUM(COALESCE(returns_net_loss, 0)) AS returns_net_loss,
        SUM(COALESCE(catalog_net_loss, 0)) AS catalog_net_loss,
        SUM(COALESCE(web_net_profit, 0)) AS web_net_profit,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS transaction_count
    FROM base
    GROUP BY s_store_id, i_category
),
final AS (
    SELECT
        s_store_id,
        i_category,
        sales_net_profit,
        returns_net_loss,
        catalog_net_loss,
        web_net_profit,
        total_quantity,
        transaction_count,
        (sales_net_profit + web_net_profit - returns_net_loss - catalog_net_loss) AS net_contribution
    FROM aggregated
    WHERE (sales_net_profit + web_net_profit - returns_net_loss - catalog_net_loss) > (
        SELECT AVG(sales_net_profit + web_net_profit - returns_net_loss - catalog_net_loss)
        FROM aggregated
    )
)
SELECT
    ROW_NUMBER() OVER (ORDER BY net_contribution DESC) AS row_num,
    s_store_id,
    i_category,
    sales_net_profit,
    returns_net_loss,
    catalog_net_loss,
    web_net_profit,
    net_contribution,
    total_quantity,
    transaction_count
FROM final
ORDER BY net_contribution DESC, s_store_id
