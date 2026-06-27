WITH returns_detail AS (
    SELECT
        s.s_store_name,
        s.s_state,
        i.i_category,
        r.r_reason_desc,
        cd.cd_gender,
        ca.ca_city,
        SUM(sr.sr_return_quantity) AS total_quantity,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE s.s_state = 'CA'
      AND ca.ca_city = 'Los Angeles'
    GROUP BY s.s_store_name,
             s.s_state,
             i.i_category,
             r.r_reason_desc,
             cd.cd_gender,
             ca.ca_city
),
store_category_totals AS (
    SELECT
        s_store_name,
        s_state,
        i_category,
        SUM(total_quantity) AS category_quantity,
        SUM(total_return_amount) AS category_return_amount,
        SUM(total_net_loss) AS category_net_loss
    FROM returns_detail
    GROUP BY s_store_name,
             s_state,
             i_category
)
SELECT
    rd.s_store_name,
    rd.s_state,
    rd.i_category,
    rd.r_reason_desc,
    rd.cd_gender,
    rd.ca_city,
    rd.total_quantity,
    rd.total_return_amount,
    rd.total_net_loss,
    rd.avg_purchase_estimate,
    (rd.total_quantity / c.category_quantity) * 100 AS pct_quantity_by_reason,
    (rd.total_return_amount / c.category_return_amount) * 100 AS pct_return_amount_by_reason,
    (rd.total_net_loss / c.category_net_loss) * 100 AS pct_net_loss_by_reason,
    RANK() OVER (PARTITION BY rd.s_store_name, rd.i_category ORDER BY rd.total_return_amount DESC) AS reason_rank
FROM returns_detail rd
JOIN store_category_totals c
  ON rd.s_store_name = c.s_store_name
 AND rd.s_state = c.s_state
 AND rd.i_category = c.i_category
ORDER BY rd.total_return_amount DESC
LIMIT 100
